
uses
  CRT, DOS,
  P92CORE, P92LOG, P92KBD, P92MOUSE, P92TIME, P92VGA, Bitmap;

var
  { Asset variables }
  DosuEXE: array[0..1] of TTexture;
  { Game state variables }
  t: double;


procedure OnPreload; far;
begin
  LoadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  LoadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;

procedure OnCleanup; far;
begin
  FreeBMP(dosuEXE[0]);
  FreeBMP(dosuEXE[1]);
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
    SprScaled(dosuEXE[0], 96, 24, 2)
  else
    SprScaled(dosuEXE[1], 96, 24, 2);

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

