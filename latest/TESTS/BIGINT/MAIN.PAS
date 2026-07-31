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
begin
  Int240Zero(n);

  if value < 0 then begin
    n.isNegative := true;
    value := -value;  { Note that -2147483648 overflows here }
  end else if value > 0 then
    n.isNegative := false;

  { TODO: Perform div 10000 }
end;

var
  numA, numB: TInt240;
begin

end.
