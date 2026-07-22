uses CRT;

begin

asm
  mov ax, 13h
  int 10h
end;

  readLn;

asm
  mov ax, 03h
  int 10h
end;

end.