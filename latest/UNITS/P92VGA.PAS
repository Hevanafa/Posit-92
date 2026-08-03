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

{ Forwards call to AsmPrint }
procedure Print(const text: string; const x, y: integer; const colour: byte);
procedure PascalPrint(const text: string; const x, y: integer; const colour: byte);
procedure AsmPrint(const text: string; const x, y: integer; const colour: byte);

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
  bufferInitialised: boolean;
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

procedure Print(const text: string; const x, y: integer; const colour: byte);
begin
  AsmPrint(text, x, y, colour)
end;

procedure PascalPrint(const text: string; const x, y: integer; const colour: byte);
var
  row, col, idx: integer;
  mask: byte;
begin
  for idx := 1 to length(text) do begin
    if (idx < 0) or (idx > high(byte)) then continue;

    for row := 0 to 7 do begin
      mask := font8x8[ord(text[idx]), row];

      for col := 0 to 7 do
        if (mask and (1 shl (7 - col))) <> 0 then
          AsmPSet((idx-1) * 8 + x + col, y + row, colour);
    end;
  end;
end;


procedure AsmPrint(const text: string; const x, y: integer; const colour: byte);
var
  row, col, idx: integer;
  offset: integer;
  
  mask: byte;
  ch: char;
begin
  for idx := 1 to length(text) do begin
    ch := text[idx];

    for row := 0 to 7 do begin
      mask := font8x8[ord(ch), row];
      
      for col := 0 to 7 do
        if (mask and (1 shl (7 - col))) <> 0 then
asm
{ AsmPSet }
  cmp x, 0
  jl @skip_pixel

  mov ax, VGAWidth
  cmp x, ax
  jge @skip_pixel

  cmp y, 0
  jl @skip_pixel
  mov ax, VGAHeight
  cmp y, ax
  jge @skip_pixel

  { Calculate pixel offset }
  { y + row }
  mov ax, y
  add ax, row
  mov bx, VGAWidth
  mul bx
  mov cx, ax

  { (idx-1) * 8 + x + col }
  xor ax, ax  { does the same as `mov ax, 0` }
  add ax, idx
  dec ax
  mov bx, 8
  mul bx
  add ax, x
  add ax, col
  add ax, cx

  mov bx, ax
  les di, surface
  mov al, colour
  mov es:[di+bx], al

@skip_pixel:
end;
    end;
  end;
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

procedure AsmPSet(const x, y: integer; const colour: byte); assembler;
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
  if bufferInitialised then exit;

  if (width <> DefaultVGAWidth) or (height <> DefaultVGAHeight) then
    useDefaultBufferSize := false;

  VGAWidth := width;
  VGAHeight := height;
  bufferSize := width * height;

  GetMem(surface, bufferSize);

  bufferInitialised := true;
end;

procedure FreeBuffer;
begin
  if bufferInitialised then begin
    freeMem(surface, bufferSize);
    surface := nil;
    bufferInitialised := false;
  end;
end;

begin
  useDefaultBufferSize := true;
  VGAWidth := DefaultVGAWidth;
  VGAHeight := DefaultVGAHeight;
  bufferSize := VGAWidth * VGAHeight;
end.

