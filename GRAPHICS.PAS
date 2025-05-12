{ Primitives }

unit Graphics;

interface

procedure circ(cx, cy, radius: integer; colour: byte);
procedure circfill(cx, cy, radius: integer; colour: byte);
procedure line(x1, y1, x2, y2: integer; colour: byte);
procedure rect(x0, y0, x1, y1: integer; colour: byte);
procedure rectfill(x0, y0, x1, y1: integer; colour: byte);


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


procedure line(x1, y1, x2, y2: integer; colour: byte);
var
  dx, dy, sx, sy, err, e2: integer;
begin
  dx := abs(x2 - x1);
  dy := abs(y2 - y1);

  if x1 < x2 then sx := 1 else sx := -1;
  if y1 < y2 then sy := 1 else sy := -1;

  err := dx - dy;

  while (x1 <> x2) or (y1 <> y2) do begin
    pset(x1, y1, colour);
    e2 := 2 * err;

    if e2 > -dy then begin
      err := err - dy;
      x1 := x1 + sx;
    end;

    if e2 < dx then begin
      err := err + dx;
      y1 := y1 + sy;
    end;
  end;

  pset(x1, y1, colour)
end;


procedure rect(x0, y0, x1, y1: integer; colour: byte);
var
  a, b, temp: integer;
begin
  if x0 > x1 then begin
    temp := x0; x0 := x1; x1 := temp
  end;
  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;
  for b:=y0 to y1 do begin
    pset(x0, b, colour);
    pset(x1, b, colour)
  end;
  for a:=x0 to x1 do begin
    pset(a, y0, colour);
    pset(a, y1, colour)
  end;
end;


procedure rectfill(x0, y0, x1, y1: integer; colour: byte);
var
  a, b, temp: integer;
begin
  if x0 > x1 then begin
    temp := x0; x0 := x1; x1 := temp
  end;
  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;
  for b:=y0 to y1 do
    for a:=x0 to x1 do
      pset(a, b, colour);
end;


end.
