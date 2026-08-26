{
  Maths unit
  Part of Posit-92 game engine
}

unit Maths;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

function Clamp(const value, min, max: double): double;
function Min(const a, b: double): double;
function Max(const a, b: double): double;
function Deg2Rad(const deg: double): double;
function Rad2Deg(const rad: double): double;
function I32Power(const i, exp: longint): longint;
function F32Power(const i: double; exp: longint): double;
function Floor(const value: double): integer;
function Ceil(const value: double): integer;
function ArcTan2(const y, x: double): double;


implementation

uses Panic;

function Clamp(const value, min, max: double): double;
begin
  if value < min then
    Clamp := min
  else if value > max then
    Clamp := max
  else
    Clamp := value;
end;

function Min(const a, b: double): double;
begin
  Min := 0.0;
  if a<=b then Min:=a
  else if a>b then Min:=b
end;

function Max(const a, b: double): double;
begin
  Max := 0.0;
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

function F32Power(const i: double; exp: longint): double;
var
  a: longint;
  result: double;
begin
  if exp < 0 then PanicHalt('f32power: Negative exp isn''t supported!');
  if exp = 0 then begin F32Power := 1; exit end;
  if exp = 1 then begin F32Power := i; exit end;

  result := i;
  for a := 2 to exp do
    result := result * i;

  F32Power := result
end;

function Floor(const value: double): integer;
begin
  if value < 0 then begin
    if trunc(value) = value then
      Floor := trunc(value)
    else
      Floor := trunc(value - 1);
  end else
    Floor := trunc(value);
end;

function Ceil(const value: double): integer;
begin
  if value > 0 then begin
    if trunc(value) = value then
      Ceil := trunc(value)
    else
      Ceil := trunc(value + 1);
  end else
    Ceil := trunc(value);
end;

function ArcTan2(const y, x: double): double;
begin
  if x > 0 then
    ArcTan2 := arctan(y / x)
  else if (x < 0) and (y >= 0) then
    ArcTan2 := arctan(y / x) + pi
  else if (x < 0) and (y < 0) then
    ArcTan2 := arctan(y / x) - pi
  else if (x = 0) and (y > 0) then
    ArcTan2 := pi / 2
  else if (x = 0) and (y < 0) then
    ArcTan2 := -pi / 2
  else { if (x = 0) and (y = 0) then }
    ArcTan2 := 0;  { undefined }
end;

end.
