{ Clear screen demo }

uses CRT;

procedure fullCls;
begin
asm
  { Assign ES:DI to [$A000:0] }
  mov ax, $A000
  mov es, ax

  cld { Clear direction -- Make sure DI moves forward }

  mov di, 0

  { Begin fill screen }
  mov al, 15  { bright white }
  mov cx, 64000 { byte count to fill }

  rep stosb  { Repeat + store string byte, using CX and AL implicitly }
end;
end;


{ Fills both half top and half bottom of the VGA screen }
procedure halfCls;
const
  colour1 = 1;
  colour2 = $0E;
begin

asm
  { Sets ES:DI to [$A000:0] }
  mov ax, $a000
  mov es, ax

  cld  { Clear direction -- make sure DI moves forward }

  { Half top }
  mov di, 0
  mov cx, 32000
  mov al, colour1
  rep stosb  { This resets CX to 0 }

  { Formula:
    `rep stosb` writes AL value into ES:DI, CX times }

  mov di, 32000
  mov cx, 32000
  mov al, colour2
  rep stosb
end;

end;

begin
asm
  mov ax, 13h
  int 10h
end;

  { fullCls; }
  halfCls;
  readLn;

asm
  mov ax, 10h
  int 10h
end;

end.
