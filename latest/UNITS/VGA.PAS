unit VGA;

interface

type
  PSurfaceBuffer = ^TSurfaceBuffer;
  TSurfaceBuffer = array[0..63999] of byte;

  PFont8x8 = ^TFont8x8;
  TFont8x8 = array[0..255, 0..7] of byte;

const
  VgaWidth = 320;
  VgaHeight = 200;

var
  surface: PSurfaceBuffer;

procedure InitMode13h;
procedure InitModeText;

{ This loads the 8x8 font }
procedure LoadCGAFont;
function BorrowCGAFont: PFont8x8;

procedure InitBuffer;
procedure FreeBuffer;

{ Routes to AsmCls }
procedure Cls(const colour: byte);
procedure PascalCls(const colour: byte);
procedure AsmCls(const colour: byte);

{ Routes to AsmPrint }
procedure Print(const text: string; const x, y: integer; const colour: byte);
procedure PascalPrint(const text: string; const x, y: integer; const colour: byte);
procedure AsmPrint(const text: string; const x, y: integer; const colour: byte);

{ Routes to AsmPset }
procedure Pset(const x, y: integer; const colour: byte);
procedure PascalPset(const x, y: integer; const colour: byte);
procedure AsmPset(const x, y: integer; const colour: byte);

{ Routes to PascalFlush }
procedure Flush;
procedure PascalFlush;
procedure AsmFlush;


implementation

uses DOS, Panic;

const
  bufferSize = 64000;
var
  a, b: integer;
  font8x8: TFont8x8;
  bufferInitialised: boolean;

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
  fillChar(surface^, bufferSize, colour)
end;

procedure AsmCls(const colour: byte); assembler;
asm
  push es
  les di, surface  { Set ES:DI to surface pointer }
  cld  { Make sure DI move forward }
  mov al, colour
  mov ah, colour
  mov cx, 32000
  rep stosw
  pop es
end;

procedure Print(const text: string; const x, y: integer; const colour: byte);
begin
  AsmPrint(text, x, y, colour)
end;

procedure PascalPrint(const text: string; const x, y: integer; const colour: byte);
var
  row, col, idx: integer;
  pos: integer;
  mask: byte;
begin
  for idx := 1 to length(text) do begin
    if (idx < 0) or (idx > 127) then continue;

    for row := 0 to 7 do begin
      mask := font8x8[ord(text[idx]), row];
      for col := 0 to 7 do
        if (mask and (1 shl (7 - col))) <> 0 then begin
          AsmPset((idx-1) * 8 + x + col, y + row, colour);
          { pos := (y+row) * 320 + (idx-1)*8 + (x+col);
          surface^[pos] := colour; }
          { Pset((idx-1) * 8 + x + col, y + row, colour); }
          end;
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
{ AsmPset }
  cmp x, 0
  jl @skip_pixel
  cmp x, 320
  jge @skip_pixel
  cmp y, 0
  jl @skip_pixel
  cmp y, 200
  jge @skip_pixel

  { Calculate pixel offset }
  { y + row }
  mov ax, y
  add ax, row
  mov bx, 320
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


procedure Pset(const x, y: integer; const colour: byte);
begin
  AsmPset(x, y, colour)
end;

procedure PascalPset(const x, y: integer; const colour: byte);
begin
  if (x < 0) or (x >= 320) or (y < 0) or (y >= 200) then exit;
  surface^[y * 320 + x] := colour;
end;

procedure AsmPset(const x, y: integer; const colour: byte); assembler;
asm
  { Bounds check }
  cmp y, 0
  jl @skip
  cmp y, 200
  jge @skip

  cmp x, 0
  jl @skip
  cmp x, 320
  jge @skip

  { Calculate offset: y * 320 + x }
  mov ax, y
  mov bx, 320
  mul bx      { DX:AX = y * 320 --> result in AX }
  add ax, x   { AX = y * 320 + x }

  { Copy AX to BX because ES:[BX] is valid, not ES:[DI+AX] }
  mov bx, ax

  { Write byte to the `surface` array }
  les di, surface { ES:DI = surface^ }
  mov al, colour
  { mov es:[di+ax], colour } { <-- Invalid register combination }
  mov es:[di+bx], al
@skip:
end;


procedure Flush;
begin
  PascalFlush
  { AsmFlush }
end;


procedure PascalFlush;
begin
  Move(surface^, Mem[$A000:0], 64000)
end;

{
  Based on fastFlush from FPS.PAS and MOVEMOU4.PAS
  lds si, surface: loads DS:SI from surface
  mov es, $a000: targets the VGA framebuffer
  xor di, di: start writing at offset 0000
  rep movsw: fast string move; copies 2 bytes per iteration
  push/pop: preserves segment registers to avoid corruption
}
procedure AsmFlush; assembler;
asm
  push ds
  push es

  lds si, surface { Load DS:SI with source pointer }
  mov ax, $a000
  mov es, ax      { Set ES to VGA segment }
  xor di, di      { DI = 0 (Destination offset) }

  mov cx, 32000   { 64000 bytes / 2 = 32000 words }
  rep movsw       { Copy CX words from DS:SI to ES:DI }

  pop es
  pop ds
end;

procedure InitBuffer;
begin
  if not bufferInitialised then
    getMem(surface, bufferSize);
end;

procedure FreeBuffer;
begin
  if bufferInitialised then begin
    freeMem(surface, bufferSize);
    surface := nil
  end;
end;

end.
