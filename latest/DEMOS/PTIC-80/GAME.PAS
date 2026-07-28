
uses
  CRT, DOS,
  P92Core, Logger, P92KBD, P92Mouse, Timing, P92VGA, Bitmap;

var
  { Asset variables }
  DosuEXE: array[0..1] of PBitmap;
  { Game state variables }
  t: double;


procedure OnPreload; far;
begin
  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;

procedure OnCleanup; far;
begin
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);
end;

procedure OnReady; far;
begin
  t := 0.0;
end;

procedure Update; far;
begin
  if isKeyDown(SC_ESCAPE) then SignalDone;

  t:=t+DeltaTime
end;


procedure Draw; far;
begin
  cls($7D);

  if (trunc(t * 1.5) and 1) = 0 then
    SprScaled(dosuEXE[0], 96, 24, 13, 2)
  else
    SprScaled(dosuEXE[1], 96, 24, 13, 2);

  print('Hello world!', (240-96) div 2, 84, 15);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.BufferWidth := 240;
  appConfig.BufferHeight := 136;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

