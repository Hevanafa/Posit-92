uses CRT;

var
  num: word;
begin
  num := 0;
  asm
    mov num, 1234
  end;

  writeLn('Num:', num);
  readLn;
end.