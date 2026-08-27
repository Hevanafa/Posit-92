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

  { Edge case }
  if length(src) = 0 then begin
    WriteLn('Empty input!');
    exit
  end;

  { Perform integer validation }
  a := 1;
  if src[a] = '-' then inc(a);
  while a <= length(src) do begin
    if not (src[a] in ['0'..'9']) then begin
      WriteLn('"' + src + '" is not a valid integer!');
      exit
    end;

    inc(a);
  end;

  { Begin parser }
  if src[1] = '-' then begin
    n.isNegative := true;
    delete(src, 1, 1)
  end;

  { Edge case for "-" string }
  if length(src) = 0 then begin
    WriteLn('Bare minus sign is invalid!');
    exit
  end;

  { Trim leading zeroes }
  while (length(src) > 1) and (src[1] = '0') do
    delete(src, 1, 1);

  { Edge case for overflow }
  if length(src) > Int240Limbs * 4 then begin
    WriteLn('Number is too large!');
    exit
  end;

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

  { Edge case for "-0" }
  if Int240IsZero(n) then n.isNegative := false;
end;


procedure Int240RawAdd(const a, b: TInt240; var c: TInt240);
var
  limbIdx: integer;
  carry, sum: longint;
begin
  Int240Zero(c);
  carry := 0;

  for limbIdx := 0 to Int240Limbs - 1 do begin
    sum := longint(a.digits[limbIdx]) + longint(b.digits[limbIdx]) + carry;
    c.digits[limbIdx] := word(sum mod 10000);
    carry := sum div 10000
  end;

  { carry > 0 at this point means overflow past the 60th digit }
end;

var
  numA, numB, numC: TInt240;
begin
  writeln('SizeOf(TInt240): ', sizeof(TInt240));
  Int240FromLongInt(numA, 1234987);
  Int240Zero(numB);

  writeln('numA: ' + Int240ToString(numA));
  writeln('numB: ' + Int240ToString(numB));

  Int240FromString(numA, '18446744673709551616');
  writeln('What is numA? ' + Int240ToString(numA));

  { Test for invalid inputs }
  Int240FromString(numA, ' -abcdef');
  Int240FromString(numA, ' - ');

  { Valid big number }
  Int240FromString(numA, '123456789012345678901234567890123456789012345678901234567890');
  writeln(Int240ToString(numA));
  { Expected overflow error }
  Int240FromString(numA, '1234567890123456789012345678901234567890123456789012345678901');

  Int240FromLongInt(numA, 5100);
  Int240FromLongInt(numB, 6700);
  Int240RawAdd(numa, numb, numc);
  writeln('5100 + 6700 = ' + Int240ToString(numc));
end.
