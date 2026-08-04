unit P92VGA;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

const
  DefaultVGAWidth: word = 320;
  DefaultVGAHeight: word = 200;

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..0] of byte;

  PFont8x8 = ^TFont8x8;
  TFont8x8 = array[0..255, 0..7] of byte;

var
  VGAWidth, VGAHeight: word;
  surface: PByteArray;

procedure InitMode13h;
procedure InitModeText;

procedure Vert400;

{ This loads the 8x8 font }
procedure LoadCGAFont;
function BorrowCGAFont: PFont8x8;

procedure InitBuffer(const width, height: word);
procedure FreeBuffer;

{ Forwards call to AsmCls }
procedure Cls(const colour: byte);
procedure PascalCls(const colour: byte);
procedure AsmCls(const colour: byte);

function DrawCGAGlyph(const ch: char; const x, y: integer; const colour: byte): word;
procedure Print(const text: string; const x, y: integer; const colour: byte);

{ Forwards call to AsmPset }
procedure PSet(const x, y: integer; const colour: byte);
procedure PascalPSet(const x, y: integer; const colour: byte);
procedure UnsafePascalPSet(const x, y: integer; const colour: byte);

procedure AsmPSet(const x, y: integer; const colour: byte);
procedure AsmPSetOffset(const bufOffset: Word; const colour: byte);
procedure UnsafeAsmPSet(const x, y: integer; const colour: byte);

{ Forwards call to AsmFlush }
procedure PresentMode13h;
procedure PascalPresentMode13h;
procedure AsmPresentMode13h;

{ Only applicable to the 400 scanlines mode }
procedure PresentModeX;


implementation

uses DOS, Panic;

var
  useDefaultBufferSize: boolean;
  isBufferInitialised: boolean;
  bufferSize: word;
  font8x8: TFont8x8;

procedure InitMode13h; assembler;
asm
  mov ax, 0013h
  int 10h
end;

procedure InitModeText; assembler;
asm
  mov ax, 0003h
  int 10h
end;

{ Taken from https://github.com/skoelle/turbopascal-xlib-unit/blob/main/xlibunit.pas }
procedure Vert400; assembler;
asm
  { Assign the maximum scanline }
  mov dx, 3D4h
  mov al, 9  { This selects register 9, which is the "maximum scanlines" register }
  out dx, al

  { Switch to port 3D5h }
  inc dx
  in al, dx
  and al, 01110000b  { This clears bits 0-3, preserving bits 4-6 }
  out dx, al
end;

{ Load 8x8 font }
procedure LoadCGAFont;
var
  Regs: Registers;
begin
  { Get the 8x8 font pointer }
  regs.ah := $11;
  regs.al := $30;
  regs.bh := 3; { 8x8 font }
  Intr($10, Regs);

  { Copy font data to buffer }
  Move(Mem[Regs.ES:Regs.BP], font8x8, sizeOf(font8x8));
end;

function BorrowCGAFont: PFont8x8;
begin
  BorrowCGAFont := @font8x8
end;


procedure Cls(const colour: byte);
begin
  AsmCls(colour)
end;


procedure PascalCls(const colour: byte);
begin
  { Important: dereference buffer! }
  FillChar(surface^, BufferSize, colour)
end;

procedure AsmCls(const colour: byte);
var
  size: word;
begin
  size := bufferSize div 2;
asm
  push es
  les di, surface  { Set ES:DI to surface pointer }
  cld  { Make sure DI move forward }
  mov al, colour
  mov ah, colour
  { mov cx, 32000 }  { 320x200/2 }
  mov cx, size
  rep stosw
  pop es
end;
end;

{ Always returns 8, following the BMFont's xadvance pattern
  Base reference for DrawCGAGlyph }
function DrawCGAGlyphBaseRef(const ch: char; const x, y: integer; const colour: byte): word;
var
  row, col: word;
  mask: byte;
begin
  for row := 0 to 7 do begin
    mask := font8x8[ord(ch), row];

    if mask = 0 then continue;

    for col := 0 to 7 do
      if (mask and ($80 shr col)) <> 0 then
        AsmPSet(x + col, y + row, colour);
  end;
end;

{ See DrawCGAGlyphBaseRef above to see the base implementation }
function DrawCGAGlyph(const ch: char; const x, y: integer; const colour: byte): word;
var
  row, col: word;
  mask: byte;
  baseOffset, destOffset: word;

  rowStart, rowEnd: integer;
  colStart, colEnd: integer;
  clipMask: byte;

  surfacePtr: PByteArray;
begin
  DrawCGAGlyph := 8;

  surfacePtr := surface;

  { Handle edge cases }

  { Edge case: off-screen }
  if (x <= -8) or (x >= VGAWidth)
    or (y <= -8) or (y >= VGAHeight) then exit;

  { Visible row range }
  if y < 0 then
    rowStart := -y
  else
    rowStart := 0;

  if y + 7 >= VGAHeight then
    rowEnd := VGAHeight - 1 - y
  else
    rowEnd := 7;

  { Visible col range }
  if x < 0 then
    colStart := -x
  else
    colStart := 0;

  if x + 7 >= VGAWidth then
    colEnd := VGAWidth - 1 - x
  else
    colEnd := 7;

  clipMask := ($FF shr colStart) and ($FF shl (7 - colEnd));

  { implementation with base offset }
  baseOffset := (y + rowStart) * VGAWidth + x;

  for row := rowStart to rowEnd do begin
    mask := font8x8[ord(ch), row] and clipMask;

    if mask = 0 then continue;

    destOffset := baseOffset + (row - rowStart) * VGAWidth;

    { Base col loop implementation }
    { for col := colStart to colEnd do
      if (mask and ($80 shr col)) <> 0 then
        surfacePtr^[destOffset + col] := colour; }

    asm
      les di, surfacePtr
      add di, destOffset
      add di, colStart

      mov al, mask
      mov cl, byte ptr colStart
      shl al, cl  { align first visible bit to bit 7 }

      mov bl, colour

      { Load CX with the visible column count }
      mov cx, colEnd
      sub cx, colStart
      inc cx

    @col_loop:
      shl al, 1
      jnc @skip

      mov es:[di], bl

    @skip:
      inc di
      dec cx
      jnz @col_loop
    end;
  end;
end;

procedure Print(const text: string; const x, y: integer; const colour: byte);
var
  idx: integer;
  xOffset: integer;
begin
  xOffset := 0;
  for idx := 1 to length(text) do
    inc(xOffset, DrawCGAGlyph(text[idx], x + xOffset, y, colour));
end;


procedure PSet(const x, y: integer; const colour: byte);
begin
  AsmPSet(x, y, colour)
end;

procedure PascalPSet(const x, y: integer; const colour: byte);
begin
  if (x < 0) or (x >= VGAWidth) or (y < 0) or (y >= VGAHeight) then exit;
  surface^[y * VGAWidth + x] := colour
end;

procedure UnsafePascalPSet(const x, y: integer; const colour: byte);
begin
  surface^[y * VGAWidth + x] := colour
end;

procedure AsmPSet(const x, y: integer; const colour: byte);
begin
{$IFDEF P92_MODE_X}
  PanicHalt('Not supported in mode X');
{$ENDIF}
asm
  { Bounds check }
  mov ax, VGAHeight
  cmp y, ax
  jae @skip

  mov bx, VGAWidth
  cmp x, bx
  jae @skip

  { Calculate offset: y * 320 + x }
  mov ax, y
  { BX still has the value of VGAWidth,
  and the result goes to AX }
  mul bx
  add ax, x   { AX = y * 320 + x }

{
  Load BX with AX because the ES:[DI+BX] syntax is valid,
  but not ES:[DI+AX]
}
  mov bx, ax

  { Load ES:DI with the address to the backbuffer (surface) }
  les di, surface
  mov al, colour
  { mov es:[di+ax], colour } { <-- Invalid register combination }
  mov es:[di+bx], al
@skip:
end;
end;

procedure AsmPSetOffset(const bufOffset: Word; const colour: byte); assembler;
asm
  les di, surface
  add di, bufOffset
  mov al, colour
  mov es:[di], al
end;

procedure UnsafeAsmPSet(const x, y: integer; const colour: byte); assembler;
asm
{ Calculate offset: y * 320 + x }
mov ax, y
mov bx, VGAWidth
mul bx
add ax, x

{ Load BX with AX because ES:[DI+BX] is valid, but not ES:[DI+AX] }
mov bx, ax

{ Load ES:DI with the address to the backbuffer (surface) }
les di, surface
mov al, colour
{ mov es:[di+ax], colour } { <-- Invalid register combination }
mov es:[di+bx], al
end;

procedure PresentMode13h;
begin
  { PascalPresentMode13h }
  AsmPresentMode13h
end;


procedure PascalPresentMode13h;
var
  y, srcOffset, destOffset: word;
begin
  if useDefaultBufferSize then
    Move(surface^, Mem[$A000:0], BufferSize)
  else
    for y := 0 to VGAHeight - 1 do begin
      srcOffset := y * VGAWidth;
      destOffset := y * DefaultVGAWidth;

      Move(
        PByteArray(surface)^[srcOffset],
        mem[$A000:destOffset],
        VGAWidth);
    end;
end;

{
  Based on fastFlush from FPS.PAS and MOVEMOU4.PAS

  lds si, surface: loads DS:SI from surface
  mov es, $a000: targets the VGA framebuffer
  xor di, di: start writing at offset 0000
  rep movsw: fast string move; copies 2 bytes per iteration
  push/pop: preserves segment registers to avoid corruption
}
procedure AsmPresentMode13h;
var
  y, halfWidth: word;
  srcOffset, destOffset: word;
  w, defaultW, h: word; { Accessible via SS:BP }
begin
  if useDefaultBufferSize then begin
asm
  push ds
  push es

  lds si, surface { Load DS:SI with source pointer }

  mov ax, $a000
  mov es, ax      { Set ES to VGA segment }
  xor di, di      { Reset DI (Destination srcOffset) }

  mov cx, 32000   { 64000 bytes / 2 = 32000 words }
  rep movsw       { Copy CX words from DS:SI to ES:DI }

  pop es
  pop ds
end;
  exit
  end;

  { PresentMode13h per scanline }
  w := VGAWidth;
  defaultW := DefaultVGAWidth;
  h := VGAHeight;

  halfWidth := VGAWidth div 2;

asm
  push ds
  push es

  { Assign ES:DI to $A000:0000 }
  mov ax, $A000
  mov es, ax
  xor di, di

  { for (y = 0; y < VgaWidth; y++) }
@y_init:
  mov y, 0
  mov srcOffset, 0

  lds si, surface
  mov bx, si

@y_body:
  { srcOffset := y * VGAWidth }
  mov ax, y
  mul w

  mov si, bx
  add si, ax

  { destOffset := y * DefaultVGAWidth }
  mov ax, y
  mul defaultW
  mov di, ax

  mov cx, halfWidth
  rep movsw

@y_last:
  inc y

@y_check:
  mov ax, h
  cmp y, ax
  jl @y_body

@skip:
  pop es
  pop ds
end;
end;


procedure PresentModeX;
var
  y, offset, screenOffset: longint;
begin
  port[$3C4] := 2;    { Select Map Mask register }
  { port[$3C5] := $02; }  { Enable plane 1 only }
  port[$3C5] := $0F;  { Enable all planes }

  for y:=0 to DefaultVGAHeight - 1 do begin
    offset := y * DefaultVGAWidth;
    screenOffset := y * DefaultVGAWidth;

    Move(surface^[offset], Mem[$A000:screenOffset], DefaultVGAWidth);
    { Move(surface^[offset], Mem[$B000:screenOffset], DefaultVGAWidth); }
  end;
end;


procedure InitBuffer(const width, height: word);
begin
  if isBufferInitialised then exit;

  if width > DefaultVGAWidth then
    PanicHalt('InitBuffer: Buffer width can''t be more than the VGA screen width!');

  if height > DefaultVGAHeight then
    PanicHalt('InitBuffer: Buffer height can''t be more than the VGA screen height!');

  if (width <> DefaultVGAWidth) or (height <> DefaultVGAHeight) then
    useDefaultBufferSize := false;

  VGAWidth := width;
  VGAHeight := height;
  bufferSize := width * height;

  GetMem(surface, bufferSize);

  isBufferInitialised := true;
end;

procedure FreeBuffer;
begin
  if isBufferInitialised then begin
    freeMem(surface, bufferSize);
    surface := nil;
    isBufferInitialised := false;
  end;
end;

begin
  useDefaultBufferSize := true;
  VGAWidth := DefaultVGAWidth;
  VGAHeight := DefaultVGAHeight;
  bufferSize := VGAWidth * VGAHeight;
end.

