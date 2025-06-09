unit Maths;

interface

function min(const a, b: double): double;
function max(const a, b: double): double;
function deg2rad(const deg: double): double;
function rad2deg(const rad: double): double;
function i32power(const i, exp: longint): longint;


implementation

function min(const a, b: double): double;
begin
  if a<=b then min:=a
  else if a>b then min:=b
end;

function max(const a, b: double): double;
begin
  if a<b then max:=b
  else if a>=b then max:=a
end;

function deg2rad(const deg: double): double;
begin
  deg2rad := deg / 180 * pi
end;

function rad2deg(const rad: double): double;
begin
  rad2deg := rad * 180 / pi
end;

function i32power(const i, exp: longint): longint;
var
  a, result: longint;
begin
  if exp < 0 then panicHalt('i32power: Negative exp isn''t supported!');
  if exp = 0 then begin i32power := 1; exit end;
  if exp = 1 then begin i32power := i; exit end;

  result := i;
  for a := 2 to exp do
    result := result * i;
  i32power := result
end;

end.