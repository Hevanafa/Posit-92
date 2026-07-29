
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

procedure InitModeY;
begin
  port[$3C4] := $04;
  port[$3C5] := $06;

  port[$3D4] := $14;
  port[$3D5] := $00;

  port[$3D4] := $17;
  port[$3D5] := $E3;

  port[$3C4] := $02;
  port[$3C5] := $0F;

  FillChar(mem[$A000:0000], $FFFF, $0F);
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
  InitModeY;
  writeln('Hello!');
  readln;
  InitModeText;
end.
