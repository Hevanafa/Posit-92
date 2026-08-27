{
  For-loop demonstration
  29-05-2025
}

uses CRT;

var
  a, b: word;
begin

  a := 0; b := 0;

asm
@while_begin:
  cmp a, 9
  ja @while_end

  add b, 2

  inc a
  jmp @while_begin

@while_end:
end;

  writeLn('a is ', a, ', b is ', b);
  readLn
end.
