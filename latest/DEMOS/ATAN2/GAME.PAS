
uses
  CRT, DOS,
  P92Core, Bitmap, Conv, FPS, Graphics, Logger, Keyboard, Maths, Mouse, Timing, VGA;

var
  { Asset variables }
  DosuEXE: array[0..1] of PBitmap;
  { Game state variables }
  t: double;
  x, y: double;


procedure OnPreload; far;
begin
  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;

procedure OnCleanup; far;
begin
  FreeBMP(DosuEXE[0]);
  FreeBMP(DosuEXE[1]);
end;

procedure OnReady; far;
begin
  t := 0.0;
  x := 200;
  y := 150;
end;

function GetAngle(const x0, y0, x1, y1: double): double;
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

  GetAngle := result
end;


procedure Update; far;
begin
  if isKeyDown(SC_ESCAPE) then SignalDone;

  if isKeyDown(SC_W) then y := y - DeltaTime * 60;
  if isKeyDown(SC_S) then y := y + DeltaTime * 60;
  if isKeyDown(SC_A) then x := x - DeltaTime * 60;
  if isKeyDown(SC_D) then x := x + DeltaTime * 60;

  t:=t+DeltaTime
end;


procedure Draw; far;
var
  angle: double;
begin
  cls($7D);

  { TODO: Your drawing code here }

  circfill(160, 100, 20, 12);
  circfill(trunc(x), trunc(y), 8, 15);

  angle := GetAngle(x, y, 160, 100);
  print('Angle: ' + f32str(angle), 0, 8, 7);
  print('Angle (deg): ' + f32str(rad2deg(angle)), 0, 16, 7);

  drawMouse;
  drawFPS;
  flush
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

