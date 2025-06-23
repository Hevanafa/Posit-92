{
  Quicksort unit implementation
  Part of Posit-92 game framework
}

unit QSort;

interface

{ Add your custom records as necessary }
procedure quickSortI16(var ary: array of integer; low, high: integer);
procedure sortI16(var ary: array of integer);


implementation

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
  { partition index }
  partitionIdx: integer;
begin
  if low < high then begin
    partitionIdx := partitionI16(ary, low, high);

    quickSortI16(ary, low, partitionIdx - 1);
    quickSortI16(ary, partitionIdx + 1, high);
  end;
end;

{ Convenience procedure }
procedure sortI16(var ary: array of integer);
begin
  quickSortI16(ary, low(ary), high(ary))
end;

end.
