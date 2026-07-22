uses
  CRT,
  Conv, Panic, QSort;


procedure printArrayI16(const ary: array of integer);
var
  a: integer;
begin
  for a:=low(ary) to high(ary) do begin
    if a >= low(ary) + 1 then
      write(', ', i32str(ary[a]))
    else
      write(ary[a]);
  end;
  writeLn
end;


procedure printArrayPEnemy(const ary: array of PEnemy);
var
  a: integer;
begin
  for a:=low(ary) to high(ary) do begin
    if ary[a] = nil then continue;

    if a >= low(ary) + 1 then
      write(', ', i32str(ary[a]^.x))
    else
      write(ary[a]^.x);
  end;
  writeLn
end;


function sum(const i, j: integer): integer;
begin
  sum := i + j
end;


var
  a, b, c: word;
  numbers: array[0..9] of integer;
  enemies: array[0..4] of PEnemy;
begin
  randomize;

  { Part 1: integer sort }
  writeLn;
  for a:=0 to high(numbers) do
    numbers[a] := random(100);

  writeLn('Original:');
  printArrayI16(numbers);

  sortI16(numbers);
  writeLn('Sorted:');
  printArrayI16(numbers);

  { Part 2: sorting a record }
  writeLn;

  for a:=0 to high(enemies) do begin
    getMem(enemies[a], sizeof(TEnemy));
    enemies[a]^.x := random(320);
    enemies[a]^.y := random(200);
  end;

  writeLn('Original:');
  printArrayPEnemy(enemies);

  sortEnemiesByX(enemies);
  writeLn('Sorted:');
  printArrayPEnemy(enemies);

  freeMem(enemies[a], sizeof(TEnemy));

  readLn
end.
