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


{ Add your custom records as necessary }
procedure quickSortI16(var ary: array of integer; low, high: integer);
procedure sortI16(var ary: array of integer);

procedure quickSortEnemiesByX(var ary: array of PEnemy; low, high: integer);
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


function partitionEnemiesByX(
  var ary: array of PEnemy;
  low, high: integer): integer;
var
  pivot, temp: PEnemy;
  a, b: integer;
begin
  { Choose the rightmost element as a pivot }
  pivot := ary[high];
  a := low - 1;

  for b := low to high - 1 do begin
    { compare(ary[b], pivot) }
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

  partitionEnemiesByX := a + 1
end;

procedure quickSortEnemiesByX(
  var ary: array of PEnemy;
  low, high: integer);
var
  partitionIdx: integer;
begin
  if low < high then begin
    partitionIdx := partitionEnemiesByX(ary, low, high);  { compare }

    quickSortEnemiesByX(ary, low, partitionIdx - 1);  { compare }
    quickSortEnemiesByX(ary, partitionIdx + 1, high);  { compare }
  end;
end;


{ Convenience procedures }
procedure sortI16(var ary: array of integer);
begin
  quickSortI16(ary, low(ary), high(ary))
end;

procedure sortEnemiesByX(var ary: array of PEnemy);
begin
  quickSortEnemiesByX(ary, low(ary), high(ary))
end;


end.
