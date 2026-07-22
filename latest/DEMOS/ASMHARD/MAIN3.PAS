uses CRT;

{ `var` makes it a pointer to a byte (passing by reference)
  `x` contains the offset address of the actual value in the data segment (DS) }
procedure addOne(var x: word);
begin
  {
  ES: extra segment
  BX: base register (2 bytes)
  les: load ES
  inc doesn't allow modification of es:[bx] directly
  AX: accumulator (AL: low byte, AH: high byte)

  Syntax for mov:
    mov destination, source
  It's a one-way copy of a value
  }

  asm
    les bx, x  { Load ES:BX with the pointer to x }
    mov al, es:[bx]
    inc al
    mov es:[bx], al
  end;
end;

{
  The same as above but with the procedure in whole assembly
  The parameters have to have the same data type as the arguments
  For example: if `x` is a `word`, so you can't pass a `byte` or an `integer`
    as the argument
}
procedure addOneAsm(var x: word); assembler;
asm
 les bx, x
 mov al, es:[bx]
 inc al
 mov es:[bx], al
end;

var
  num: word;
begin
  num := 0;
  asm
    mov num, 1234
  end;

  { addOne(num); }
  addOneAsm(num);
  writeLn('Num:', num);  { Should be 1235 }
  readLn
end.
