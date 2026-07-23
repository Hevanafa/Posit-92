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
procedure QuickSortI16(var ary: array of integer; low, high: integer);
procedure SortI16(var ary: array of integer);

procedure QuickSortEnemiesByX(var ary: array of PEnemy; low, high: integer);
procedure SortEnemiesByX(var ary: array of PEnemy);


implementation

uses Panic;

function PartitionI16(var ary: array of integer; low, high: integer): integer;
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

  PartitionI16 := a + 1
end;


procedure QuickSortI16(var ary: array of integer; low, high: integer);
var
  partitionIdx: integer;
begin
  if low < high then begin
    partitionIdx := PartitionI16(ary, low, high);

    QuickSortI16(ary, low, partitionIdx - 1);
    QuickSortI16(ary, partitionIdx + 1, high);
  end;
end;


function PartitionEnemiesByX(
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

  PartitionEnemiesByX := a + 1
end;

procedure QuickSortEnemiesByX(
  var ary: array of PEnemy;
  low, high: integer);
var
  partitionIdx: integer;
begin
  if low < high then begin
    partitionIdx := PartitionEnemiesByX(ary, low, high);  { compare }

    QuickSortEnemiesByX(ary, low, partitionIdx - 1);  { compare }
    QuickSortEnemiesByX(ary, partitionIdx + 1, high);  { compare }
  end;
end;


{ Convenience procedures }
procedure SortI16(var ary: array of integer);
begin
  QuickSortI16(ary, low(ary), high(ary))
end;

procedure SortEnemiesByX(var ary: array of PEnemy);
begin
  QuickSortEnemiesByX(ary, low(ary), high(ary))
end;


end.
