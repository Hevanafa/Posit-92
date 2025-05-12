{ Primitives }

unit Graphics;

interface

procedure circ(cx, cy, radius: integer; colour: byte);
procedure circfill(cx, cy, radius: integer; colour: byte);

implementation

uses VGA;

procedure circ(cx, cy, radius: integer; colour: byte);
var
  x, y, p: integer;
begin
  x := 0;
  y := radius;
  p := 3 - 2 * radius;

  while x <= y do begin
    pset(cx + x, cy + y, colour);
    pset(cx - x, cy + y, colour);
    pset(cx + x, cy - y, colour);
    pset(cx - x, cy - y, colour);
    pset(cx + y, cy + x, colour);
    pset(cx - y, cy + x, colour);
    pset(cx + y, cy - x, colour);
    pset(cx - y, cy - x, colour);

    if p < 0 then
      p := p+4 * x+6
    else begin
      p := p+4 * (x-y)+10;
      dec(y);
    end;
    inc(x);
  end;
end;

procedure circfill(cx, cy, radius: integer; colour: byte);
var
  x, y, p: integer;
  a: integer;
begin
  x := 0;
  y := radius;
  p := 3 - 2 * radius;

  while x <= y do begin
    for a:=cx-x to cx+x do begin
      pset(a, cy + y, colour);
      pset(a, cy - y, colour)
    end;
    for a:=cx-y to cx+y do begin
      pset(a, cy + x, colour);
      pset(a, cy - x, colour)
    end;

    if p < 0 then
      p := p+4 * x+6
    else begin
      p := p+4 * (x-y)+10;
      dec(y)
    end;

    inc(x)
  end;
end;

end.
