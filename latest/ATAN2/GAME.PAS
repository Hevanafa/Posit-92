
uses
  CRT, DOS,
  Bitmap, Conv, FPS, Graphics, Logger, Keyboard, Maths, Mouse, Timing, VGA;

const
  SC_ESC = $01;
  SC_A = $1E;
  SC_D = $20;
  SC_S = $1F;
  SC_W = $11;

var
  done: boolean;
  t: double;
  x, y: double;
  DosuEXE: array[0..1] of PBitmap;
  { TODO: More of your game state here }


procedure INIT;
begin
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initKeyHandler;
  initMouse;
  initFPSCounter;

  { TODO: Your init code here }

  randomize;
  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');

  x := 200;
  y := 150;
end;


function getAngle(const x0, y0, x1, y1: double): double;
var
  dx, dy, result: double;
begin
  dx := x1 - x0;
  dy := y1 - y0;

  { Handle special case to prevent division by 0 }
  if dx = 0 then begin
    if dy > 0 then
      result := pi / 2
    else if dy < 0 then
      result := -pi / 2
    else  { (dx = 0) and (dy = 0) }
      result := 0;
  end else begin
    result := ArcTan(dy / dx);

    if dx < 0 then result := result + pi;
  end;

  { Normalise to range 0..2 * Pi }
  while result < 0 do
    result := result + 2 * pi;
  while result >= 2 * pi do
    result := result - 2 * pi;

  getAngle := result
end;


procedure update;
begin
  updateDeltaTime;
  updateMouse;
  incrementFPS;

  { TODO: Your update code here }

  if isKeyDown(SC_ESC) then done := true;

  if isKeyDown(SC_W) then y := y - dt * 60;
  if isKeyDown(SC_S) then y := y + dt * 60;
  if isKeyDown(SC_A) then x := x - dt * 60;
  if isKeyDown(SC_D) then x := x + dt * 60;

  t:=t+dt
end;


procedure draw;
var
  angle: double;
begin
  cls($7D);

  { TODO: Your drawing code here }

  circfill(160, 100, 20, 12);
  circfill(trunc(x), trunc(y), 8, 15);

  angle := getAngle(x, y, 160, 100);
  print('Angle: ' + f32str(angle), 0, 8, 7);
  print('Angle (deg): ' + f32str(rad2deg(angle)), 0, 16, 7);

  drawMouse;
  drawFPS;
  flush
end;


begin
  INIT;
  done := false;

  repeat
    update;
    draw
  until done;

  { TODO: Your cleanup code here }
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);

  resetMouse;
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
