uses
  CRT,
  Conv, QSort;


procedure printArray(const ary: array of integer);
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


var
  a: word;
  numbers: array[0..9] of integer;
begin
  randomize;

  for a:=0 to high(numbers) do
    numbers[a] := random(100);

  writeLn('Original:');
  printArray(numbers);

  sortI16(numbers);
  writeLn('Sorted:');
  printArray(numbers);

  readLn
end.
