unit VGA;

interface

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..63999] of byte;

var
  surface: PByteArray;

procedure initVGAMode;
procedure initTextMode;
{ This loads the 8x8 font }
procedure loadFont;

procedure initBuffer;
procedure freeBuffer;

procedure cls(const colour: byte);
procedure pascalCls(const colour: byte);
procedure asmCls(const colour: byte);

{ calls asmPrint internally }
procedure print(const text: string; const x, y: integer; const colour: byte);
procedure pascalPrint(const text: string; const x, y: integer; const colour: byte);
procedure asmPrint(const text: string; const x, y: integer; const colour: byte);

procedure pset(const x, y: integer; const colour: byte);
procedure pascalPset(const x, y: integer; const colour: byte);
procedure asmPset(const x, y: integer; const colour: byte);

procedure flush;
procedure pascalFlush;
procedure asmFlush;


implementation

uses DOS, Panic;

const
  bufferSize = 64000;
var
  a, b: integer;
  font8x8: array[0..127, 0..7] of byte;
  bufferInitialised: boolean;


procedure initVGAMode; assembler;
asm
  mov ax, 0013h
  int 10h
end;

procedure initTextMode; assembler;
asm
  mov ax, 0003h
  int 10h
end;

{ Load 8x8 font }
procedure loadFont;
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


procedure cls(const colour: byte);
begin
  asmCls(colour)
end;


procedure pascalCls(const colour: byte);
begin
  { Important: dereference buffer! }
  fillChar(surface^, bufferSize, colour)
end;

procedure asmCls(const colour: byte); assembler;
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

procedure print(const text: string; const x, y: integer; const colour: byte);
begin
  asmPrint(text, x, y, colour)
end;

procedure pascalPrint(const text: string; const x, y: integer; const colour: byte);
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
          asmPset((idx-1) * 8 + x + col, y + row, colour);
          { pos := (y+row) * 320 + (idx-1)*8 + (x+col);
          surface^[pos] := colour; }
          { pset((idx-1) * 8 + x + col, y + row, colour); }
          end;
    end;
  end;
end;


procedure asmPrint(const text: string; const x, y: integer; const colour: byte);
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
{ asmPset }
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


procedure pset(const x, y: integer; const colour: byte);
begin
  asmPset(x, y, colour)
end;

procedure pascalPset(const x, y: integer; const colour: byte);
begin
  if (x < 0) or (x >= 320) or (y < 0) or (y >= 200) then exit;
  surface^[y * 320 + x] := colour;
end;

procedure asmPset(const x, y: integer; const colour: byte); assembler;
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


procedure flush;
begin
  asmFlush
end;


procedure pascalFlush;
begin
  panicHalt('pascalFlush: Not implemented!')
  { copy(Mem[$A000:0], surface, 64000) }
end;

{
  Based on fastFlush from FPS.PAS and MOVEMOU4.PAS
  lds si, surface: loads DS:SI from surface
  mov es, $a000: targets the VGA framebuffer
  xor di, di: start writing at offset 0000
  rep movsw: fast string move; copies 2 bytes per iteration
  push/pop: preserves segment registers to avoid corruption
}
procedure asmFlush; assembler;
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

procedure initBuffer;
begin
  if not bufferInitialised then
    getMem(surface, bufferSize);
end;

procedure freeBuffer;
begin
  if bufferInitialised then begin
    freeMem(surface, bufferSize);
    surface := nil
  end;
end;

end.
