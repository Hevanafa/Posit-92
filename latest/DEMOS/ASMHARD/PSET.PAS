uses CRT;

var
  x, y: integer;
  colour: byte;
begin
  x := 30;
  y := 10;
  colour := 15;  { bright white }

asm
  { Activate VGA mode }
  mov ax, 13h
  int 10h

  { Check bounds }
  { if (x < 0) or (x >= 320) or (y < 0) or (y >= 200) }
  cmp x, 0
  jl @skip
  cmp x, 320
  jge @skip
  cmp y, 0
  jl @skip
  cmp y, 200
  jge @skip

  { Begin plot pixel }
  mov ax, $A000
  mov es, ax  { Points the extra segment (ES) to the video RAM }

  { Create the pixel offset using AX }
  mov ax, y
  mov bx, 320  { base register }
  { ax is used implicitly by `mul`, because that's what an accumulator does }
  mul bx       { This mutates ax like this: ax = ax * bx }
  add ax, x

  {
  Assign destination index (DI) from the previous segment
  Using this formula: ES:DI, which is basically [ES + DI] in C
  }
  mov di, ax
  mov al, colour
  stosb  { store AL at ES:DI, then `inc DI` implicitly }
@skip:
end;

readLn;

asm
  mov ax, 3
  int 10h
end;

end.

