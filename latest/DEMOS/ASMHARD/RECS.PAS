uses CRT;

type
  PAnimal = ^TAnimal;
  TAnimal = record
    length: word;  { Offset 0 }
    height: word;  { Offset 2 }
    name: string
  end;

procedure process(var animal: TAnimal);
begin
asm
  les di, animal
  mov ax, es:[di]

  mov word ptr es:[di], 200  { assign 200 to length }
  mov word ptr es:[di+2], 150 { assign 150 to length }
end;
end;


procedure processPtr(const animal: PAnimal);
begin
asm
  les di, [animal]  { dereference PAnimal to TAnimal }

  { Accessing record fields }
  mov ax, es:[di]    { Offset 0, the `length` field }
  mov ax, es:[di+2]  { AX can be changed to BX, CX or DX }

  { Modifying the record fields }
  mov word ptr es:[di], 300    { animal^.length }
  mov word ptr es:[di+2], 250  { animal^.height }
end;
end;


procedure checkNil(const animal: PAnimal);
begin
asm
  les di, [animal]

  { Check if pointer is nil }
  mov ax, es
  or ax, di
  je @skip

  { Do stuff }
  mov word ptr es:[di], 900

@skip:
end;
end;

procedure updateAnimal(
  const animal: PAnimal;
  const newLength, newHeight: word);
begin
asm
  {
    Dereference PAnimal to TAnimal,
    makes ES:DI available to access via es:[di]
  }
  les di, [animal]

  { Check if pointer is nil }
  mov ax, es
  or ax, di
  je @skip

  { last parameter is pushed first:
    newHeight: bp+4
    newLength: bp+6
    animal: bp+8 }

  { newLength }
  mov ax, [bp+6]
  mov word ptr es:[di], ax
  { newHeight }
  mov ax, [bp+4]
  mov word ptr es:[di+2], ax

@skip:
end;
end;



const
  animal_size = sizeof(TAnimal);  { Assigned during compile time }

var
  a: TAnimal;
begin
  a.length := 50;
  a.height := 50;
  a.name := 'Dog';

  { process(a); }
  { processPtr(@a);
  checkNil(@a); }
  updateAnimal(@a, 320, 240);

  writeLn('Length: ', a.length);
  writeLn('Height: ', a.height);

  writeLn('size of pointer: ', sizeof(pointer));
  readLn
end.
