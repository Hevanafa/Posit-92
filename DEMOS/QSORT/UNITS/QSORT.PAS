{
  Quicksort unit implementation
  Part of Posit-92 game framework
}

unit QSort;

interface

type
  PEnemy = ^TEnemy;
  TEnemy = record
    x, y: integer;
  end;

  TEnemyCompareFunc = function(const a, b: PEnemy): integer;


{ Add your custom records as necessary }
procedure quickSortI16(var ary: array of integer; low, high: integer);
procedure sortI16(var ary: array of integer);

{
Not possible
procedure quickSortEnemies(
  var ary: array of PEnemy;
  low, high: integer;
  compare: TEnemyCompareFunc);
}
procedure quickSortEnemies(var ary: array of PEnemy; low, high: integer);
procedure sortEnemiesByX(var ary: array of PEnemy);


implementation

uses Panic;

function partitionI16(var ary: array of integer; low, high: integer): integer;
var
  pivot, a, b, temp: integer;
begin
  { Choose the rightmost element as a pivot }
  pivot := ary[high];
  a := low - 1;

  for b := low to high - 1 do begin
    if ary[b] <= pivot then begin
      inc(a);

      { perform swap }
      temp := ary[a];
      ary[a] := ary[b];
      ary[b] := temp
    end;
  end;

  temp := ary[a + 1];
  ary[a + 1] := ary[high];
  ary[high] := temp;

  partitionI16 := a + 1
end;


procedure quickSortI16(var ary: array of integer; low, high: integer);
var
  partitionIdx: integer;
begin
  if low < high then begin
    partitionIdx := partitionI16(ary, low, high);

    quickSortI16(ary, low, partitionIdx - 1);
    quickSortI16(ary, partitionIdx + 1, high);
  end;
end;


function partitionEnemies(
  var ary: array of PEnemy;
  low, high: integer
  { compare: TEnemyCompareFunc }): integer;
var
  pivot, temp: PEnemy;
  a, b: integer;
begin
  { Choose the rightmost element as a pivot }
  pivot := ary[high];
  a := low - 1;

  for b := low to high - 1 do begin
    if ary[b]^.x <= pivot^.x then begin
      inc(a);

      temp := ary[a];
      ary[a] := ary[b];
      ary[b] := temp
    end;
  end;

  temp := ary[a + 1];
  ary[a + 1] := ary[high];
  ary[high] := temp;

  partitionEnemies := a + 1
end;

procedure quickSortEnemies(
  var ary: array of PEnemy;
  low, high: integer
  { compare: TEnemyCompareFunc });
var
  partitionIdx: integer;
begin
  if low < high then begin
    partitionIdx := partitionEnemies(ary, low, high);  { compare }

    quickSortEnemies(ary, low, partitionIdx - 1);  { compare }
    quickSortEnemies(ary, partitionIdx + 1, high);  { compare }
  end;
end;


function compareEnemiesByX(const a, b: PEnemy): integer;
begin
  if a = nil then panicHalt('compareEnemiesByX: a is nil!');
  if b = nil then panicHalt('compareEnemiesByX: b is nil!');

  if a^.x < b^.x then
    compareEnemiesByX := -1
  else if a^.x > b^.x then
    compareEnemiesByX := 1
  else
    compareEnemiesByX := 0;
end;


{ Convenience procedures }
procedure sortI16(var ary: array of integer);
begin
  quickSortI16(ary, low(ary), high(ary))
end;

procedure sortEnemiesByX(var ary: array of PEnemy);
var
  compareFunc: pointer;
begin
  { compareFunc := TEnemyCompareFunc(compareEnemiesByX); }
  { quickSortEnemies(ary, low(ary), high(ary), compareFunc) }

  compareFunc := @compareEnemiesByX;
  {Invalid compiler directive: $T-}
  quickSortEnemies(ary, low(ary), high(ary))  { TEnemyCompareFunc(compareFunc) }
  {Invalid compiler directive: $T+}
end;


end.
