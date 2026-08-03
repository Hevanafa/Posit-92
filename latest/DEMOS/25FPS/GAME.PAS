uses
  CRT, DOS,
  P92Core, P92TEX, FPS, Logger, P92KBD, P92Mouse, Timing, P92VGA;

var
  { Asset variables }
  DosuEXE: array[0..1] of TBitmap;
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
  FreeBMP(dosuEXE[0]);
  FreeBMP(dosuEXE[1]);
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
    Spr(dosuEXE[0], 148, 76)
  else
    Spr(dosuEXE[1], 148, 76);

  Print('Hello world!', 160-48, 120, 15);
end;

var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.TargetFPS := 25;
  appConfig.WaitMode := P92WaitBusy;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

