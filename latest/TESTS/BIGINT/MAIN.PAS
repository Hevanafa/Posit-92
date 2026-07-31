{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses P92STR;

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

procedure Int240FromLongInt(var n: TInt240; value: longint);
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

function Int240ToString(const n: TInt240): string;
var
  a, top: integer;
  result, tmp: string;
begin
  { Edge case: zero }
  if Int240IsZero(n) then begin
    Int240ToString := '0';
    exit
  end;

  { Find the most significant non-zero limb }
  top := Int240Limbs - 1;

  while (top > 0) and (n.digits[top] = 0) do
    dec(top);

  { Top limb: no leading zeroes }
  str(n.digits[top], result);

  for a:=top - 1 downto 0 do begin
    str(n.digits[a], tmp);
    result := result + PadStart(tmp, 4, '0');
  end;

  if n.isNegative then
    result := '-' + result;

  Int240ToString := result
end;

procedure Int240FromString(var n: TInt240; src: string);
var
  a, limb: integer;
  start, code: integer;
  chunk: string;
begin
  Int240Zero(n);

  src := Trim(src);

  { TODO: Perform integer validation }

  if src[1] = '-' then begin
    n.isNegative := true;
    delete(src, 1, 1)
  end;

  { Trim leading zeroes }
  while (length(src) > 1) and (src[1] = '0') do
    delete(src, 1, 1);

  { Process numbers right to left }
  limb := 0;

  while length(src) > 0 do begin
    if length(src) >= 4 then begin
      chunk := copy(src, length(src) - 3, 4);
      delete(src, length(src) - 3, 4);
    end else begin
      chunk := src;
      src := '';
    end;

    val(chunk, n.digits[limb], code);
    inc(limb)
  end;
end;


var
  numA, numB: TInt240;
begin
  Int240FromLongInt(numA, 1234987);
  Int240Zero(numB);

  writeln('numA: ' + Int240ToString(numA));
  writeln('numB: ' + Int240ToString(numB));

  Int240FromString(numA, '18446744673709551616');
  writeln('What is numA? ' + Int240ToString(numA));
end.
