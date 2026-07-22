unit Bobbing;

interface

procedure buildSinTable;
procedure initBobbing;
procedure waitSeconds(dur: double);
procedure drawBobbingGrid(t: double);

implementation

uses Graphics, Timing, VGA;

var
  sinTable: array[0..255] of integer;

{ Used in drawBobbingGrid2 }
procedure buildSinTable;
const
  HEIGHT_SCALE = 8;
var
  a: integer;
begin
  for a:=0 to 255 do
    sinTable[a] := round(sin(a*2 * pi/256) * HEIGHT_SCALE);
end;


procedure initBobbing;
begin
  buildSinTable;
  { startTime := getTimer }
end;

procedure waitSeconds(dur: double);
var
  t0: double;
begin
  t0 := getTimer;
  while getTimer - t0 < dur do;
end;


procedure drawBobbingGrid(t: double);
const
  GRID_COLS = 16;
  GRID_ROWS = 8;
  GRID_SPACING = 32;
  cx = 160;
  cy = 100;
var
  colour: byte;
  gx, gy: integer;
  x1, y1, x2, y2: integer;
  sx1, sy1, sx2, sy2: integer;
  hz, hzNext, hzRight: integer;
begin
  { colour := 39; }
  colour := 33;  { purple to red, step=1, bg: black }
  { colour := 15; }  { black to white, step=2, bg: white }

  for gy:=1 to GRID_ROWS - 1 do
    for gx := -GRID_COLS to GRID_COLS - 1 do begin
      { height at current point }
      hz := sinTable[(gx*4 + round(t*16) + gy*2) and 255];

      { Project current point }
      x1 := (gx * GRID_SPACING) div gy;
      y1 := (hz * 32) div gy;
      sx1 := cx + x1;  sy1 := cy + y1;

      { Draw vertical line to the next row }
      hzNext := sinTable[(gx*4 + round(t*16) + (gy+1)*2) and 255];
      x2 := (gx * GRID_SPACING) div (gy + 1);
      y2 := (hzNext * 32) div (gy + 1);
      sx2 := cx + x2;  sy2 := cy + y2;

      line(sx1, sy1, sx2, sy2, COLOUR + gy);
      { line(sx1, sy1, sx2, sy2, COLOUR + gy * 2); }

      { Draw horizontal line to the right column }
      hzRight := sinTable[((gx + 1)*4 + round(t*16) + gy*2) and 255];
      x2 := ((gx + 1)*GRID_SPACING) div gy;
      y2 := (hzRight * 32) div gy;

      sx2 := cx+x2;
      sy2 := cy+y2;

      line(sx1, sy1, sx2, sy2, COLOUR + gy)
      { line(sx1, sy1, sx2, sy2, COLOUR + gy * 2) }
    end;
end;

end.
