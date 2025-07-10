unit NokiaVGA;

interface

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..4031] of byte;

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
procedure nokiaFlush;
procedure nokiaFlushX2;


implementation

uses DOS, Panic;

const
  bufferSize = 4032;
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
  mov cx, bufferSize shr 1
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
  { Check bounds }
  mov ax, y
  add ax, row
  cmp ax, 0
  jl @skip_pixel
  cmp ax, 48
  jge @skip_pixel

  mov ax, idx
  dec ax
  mov bx, 8
  mul bx
  add ax, x
  add ax, col
  cmp ax, 0
  jl @skip_pixel
  cmp ax, 84
  jge @skip_pixel

  { asmPset }
  { Calculate pixel offset }
  { y + row }
  mov ax, y
  add ax, row
  mov bx, 84
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
  cmp y, 48
  jge @skip

  cmp x, 0
  jl @skip
  cmp x, 84
  jge @skip

  { Calculate offset: y * 84 + x }
  mov ax, y
  mov bx, 84
  mul bx
  add ax, x

  mov bx, ax
  push es
  les di, surface { ES:DI = address to surface }
  mov al, colour
  mov es:[di+bx], al
  pop es
@skip:
end;


procedure flush;
begin
  nokiaFlush
end;


procedure pascalFlush;
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

procedure nokiaFlushAttempt1;
var
  y: word;
begin
asm
  push es

  { copy from data source (DS:SI) }
  push ds
  lds si, surface

@y_init:
  mov y, 0

@y_condition:
  cmp y, 48
  jge @y_end

@y_loop:
  { assign destination }
  mov ax, y
  mov bx, 84
  mul bx
  add ax, $A000
  mov es, ax

  xor di, di
  mov cx, 41
  cld
  rep movsw

@y_next:
  inc y
  jmp @y_init

@y_end:
  pop ds
  pop es
end;
end;

procedure nokiaFlush;
var
  y: word;
begin
asm
  push es

  { Assign ES:DI to VGA memory }
  mov ax, $A000
  mov es, ax
  xor di, di

  push ds
  lds si, surface
  { mov si, offset surface }

@y_init:
  mov y, 0

@y_condition:
  cmp y, 48
  jge @y_end

@y_loop:
  mov cx, 42
  cld
  rep movsw

@y_next:
  add di, 236
  inc y
  jmp @y_condition

@y_end:

  pop ds
  pop es
end;
end;


procedure nokiaFlushX2;
var
  x, y: word;
begin
asm
  push es

  { Assign ES:DI to VGA memory }
  mov ax, $A000
  mov es, ax
  xor di, di

  push ds
  lds si, surface
  { mov si, offset surface }

@y_init:
  xor y, y  { reset y to 0 }

@y_condition:
  cmp y, 48
  jge @y_end

@y_loop:

@x_init:
  xor x, x  { reset x to 0 }

@x_condition:
  cmp x, 84
  jge @x_end

@x_loop:
  mov bx, di

  mov al, ds:[si]  { obtain the source colour }
  mov es:[di], al
  inc di
  mov es:[di], al
  inc di
  mov es:[bx+320], al
  mov es:[bx+321], al

  add bx, 2
  inc si

{
  mov cx, 42
  cld
  rep movsw
}

@x_next:
  inc x
  jmp @x_condition

@x_end:

@y_next:
  add di, 472  { (320 - 168) + 320 = 152 + 320 }
  inc y
  jmp @y_condition

@y_end:

  pop ds
  pop es
end;
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
