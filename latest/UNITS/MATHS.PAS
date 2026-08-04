unit Maths;

{$IFDEF FPC}
{$MODE TP}
{$ENDIF}

interface

function Min(const a, b: double): double;
function Max(const a, b: double): double;
function Deg2Rad(const deg: double): double;
function Rad2Deg(const rad: double): double;
function I32Power(const i, exp: longint): longint;
function Floor(const value: double): integer;
function Ceil(const value: double): integer;


implementation

uses Panic;

function Min(const a, b: double): double;
begin
  if a<=b then Min:=a
  else if a>b then Min:=b
end;

function Max(const a, b: double): double;
begin
  if a<b then Max:=b
  else if a>=b then Max:=a
end;

function Deg2Rad(const deg: double): double;
begin
  Deg2Rad := deg / 180 * pi
end;

function Rad2Deg(const rad: double): double;
begin
  Rad2Deg := rad * 180 / pi
end;

function I32Power(const i, exp: longint): longint;
var
  a, result: longint;
begin
  if exp < 0 then panicHalt('i32power: Negative exp isn''t supported!');
  if exp = 0 then begin I32Power := 1; exit end;
  if exp = 1 then begin I32Power := i; exit end;

  result := i;
  for a := 2 to exp do
    result := result * i;
  I32Power := result
end;

function Floor(const value: double): integer;
begin
  Floor := trunc(value)
end;

function Ceil(const value: double): integer;
begin
  if trunc(value) = value then
    Ceil := trunc(value)
  else
    Ceil := trunc(value + 1);
end;

end.
