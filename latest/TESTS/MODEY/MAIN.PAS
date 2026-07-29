
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

begin
  InitMode13h;
  writeln('Hello!');
  readln;
  InitModeText;
end.
