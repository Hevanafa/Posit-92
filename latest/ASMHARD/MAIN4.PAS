uses CRT;

procedure checkEqual(const x: byte);
begin
  if x = 5 then
    writeLn(x, ' is 5')
  else writeLn(x, ' is not 5');
end;

procedure checkEqualAsm(x: byte);
begin
asm
  mov al, x
  cmp al, 5
  jne @skip  { Jump if not equal (JNE), the same as JNZ }
  inc al
  mov x, al
@skip:
end;
writeLn('x is now ', x) { if x is 5, this should be 6 }
end;

{ `x` is a far pointer here, not a value }
procedure checkByte(var x: byte);
begin
  { LES must be paired with ES:BX,
    this is the same as LDS to DS:BX
    Both can be used to access `x` in this procedure }

  { It's safe to use ES and LES because it doesn't affect TP7's runtime variables,
    whereas DS and LDS, because it contains TP7's strings & variables, it
    may crash if not handled carefully }

asm
  les bx, x  { Load ES:BX with the pointer to x, basically dereferencing x }
  mov al, es:[bx]

  cmp al, 42
  jne @skip
  inc al

  mov es:[bx], al  { Don't forget to load `x` after incrementing }
@skip:
end;
  writeLn('x is now ', x)
end;

var
  a: byte;
begin
  a := 42;
  clrscr;
  { checkEqual(4);
  checkEqual(5);
  checkEqualAsm(5); }
  checkByte(a);
  readLn
end.