uses CRT;

{ When called from assembly, the
  procedure must not require an
  argument }
procedure sayHi;
begin
  writeLn('Hello from assembly!');
end;

var
  a: word;
begin
  a := 0;

asm
  { Simulate for a := 0 to 9 do; }
  mov cx, 0  { init Counter register }
  { Other registers that can be used: SI, BX, DX }

@for_begin:  { This is more like a while-loop }
  cmp cx, 9
  jg @for_end

  { Do stuff }
  add a, 2
  { call sayHi }  { <-- this can only be called once }

  inc cx
  jmp @for_begin

@for_end:
end;

  clrScr;
  writeLn('a is ', a);
  readLn;

end.
