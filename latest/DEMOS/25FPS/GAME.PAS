{$DEFINE DEBUG}

uses
  CRT, DOS,
  P92Core,
  Bitmap, FPS, Logger, Keyboard, Mouse, Timing, VGA;

var
  { Asset variables }
  DosuEXE: array[0..1] of PBitmap;
  { Game state variables }
  t: double;


procedure OnPreload; far;
begin
  LoadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  LoadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;

procedure OnReady; far;
begin
  t := 0.0;
end;

procedure OnCleanup; far;
begin
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);
end;

procedure Update; far;
begin
  { Handle inputs here }
  if isKeyDown(SC_ESCAPE) then SignalDone;

  { Handle game logic here }
  
  t := t + DeltaTime
end;


procedure Draw; far;
begin
  Cls($7D);

  if (trunc(t * 1.5) and 1) = 0 then
    spr(dosuEXE[0], 148, 76, 13)
  else
    spr(dosuEXE[1], 148, 76, 13);

  print('Hello world!', 160-48, 120, 15);
  drawMouse;
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

