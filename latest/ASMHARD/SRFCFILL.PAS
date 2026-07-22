uses CRT, DOS;

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..63999] of byte;

var
  surface: PByteArray;

begin
  { init stuff here }
  getMem(surface, 64000);

asm
  { Start mode 13h }
  mov ax, 13h
  int 10h

  cld  { Clear direction -- makes sure DI moves forward }

  { Clear screen with white }
  les di, surface  { Load ES:DI to surface's pointer, index 0 }

  mov ax, 0f0fh
  mov cx, 32000
  rep stosw

  { PSET }
  mov ax, 30  { y }
  mov bx, 320
  mul bx
  add ax, 15  { x }

  mov bx, ax  { ax = y * 320 + x }
  mov al, 0   { colour }
  mov es:[di+bx], al

  { Perform flush }
  { push saves the original segment registers }
  push ds
  push es

  lds si, surface  { Point DS:SI to the `surface` array }
  mov ax, $a000
  mov es, ax       { Extended segment (ES) to the VGA memory }

  mov di, 0
  mov cx, 32000
  rep movsw  { word operation, compare movsb, which is string byte }
  { movsw reads from DS:SI }

  { Load the previously saved ES and DS from the stack }
  pop es
  pop ds
end;

  readLn;

asm
  mov ax, 03h
  int 10h
end;

  freeMem(surface, 64000);
  surface := nil
end.
