
const
  PageSize = 16000;

var
  activePage: word;

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

procedure WaitVSync;
begin
  while (port[$3DA] and $08) <> 0 do; { wait for retrace to end }
  while (port[$3DA] and $08) = 0 do;  { wait for next retrace }
end;

procedure FlipPage;
begin
  activePage := activePage xor 1;
  { TODO: Set the start address }
end;

begin
  activePage := 0;

  InitMode13h;
  writeln('Hello!');
  readln;
  InitModeText;
end.
