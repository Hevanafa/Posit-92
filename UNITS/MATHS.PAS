unit Maths;

interface

function min(const a, b: double): double;
function max(const a, b: double): double;
function deg2rad(const deg: double): double;
function rad2deg(const rad: double): double;

implementation

{ TODO: Use this in rectfill and rectfillDither instead of pset }
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

end.