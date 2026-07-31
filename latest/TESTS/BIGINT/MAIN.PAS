{$IFDEF FPC}{$MODE TP}{$ENDIF}

const
  Int240Limbs = 15;

type
  TInt240 = record
    digits: array[0..Int240Limbs-1] of word;
    isNegative: boolean;
  end;

procedure Int240Zero(var n: TInt240);
var
  a: word;
begin
  for a:=0 to Int240Limbs-1 do
    n.digits[a] := 0;
  n.isNegative := false;
end;

function Int240IsZero(const n: TInt240): boolean;
var
  a: word;
begin
  Int240IsZero := true;

  for a:=0 to Int240Limbs-1 do
    if n.digits[a] <> 0 then begin
      Int240IsZero := false;
      exit
    end;
end;

procedure Int240FromWord(var n: TInt240; const value: word; const negative: boolean);
begin
  Int240Zero(n);
  n.digits[0] := value;

  if value <> 0 then
    if negative then n.isNegative:= true
    else n.isNegative := false;
end;

procedure Int24FromLongInt(var n: TInt240; value: longint);
var
  a: word;
begin
  Int240Zero(n);

  { Edge case for -2147483648 }
  if value = low(longint) then begin
    n.isNegative := true;
    n.digits[0] := 3648;
    n.digits[1] := 4748;
    n.digits[2] := 21;
    exit
  end;

  if value < 0 then begin
    n.isNegative := true;
    value := -value;
  end;

  a := 0;
  while value > 0 do begin
    n.digits[a] := word(value mod 10000);
    value := value div 10000;
    inc(a)
  end;
end;

var
  numA, numB: TInt240;
begin

end.
