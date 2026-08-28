uses
  CRT, DOS,
  P92CORE, P92TEX, P92FPS, P92LOG, P92KBD, P92MOUSE, P92TIME, P92VGA;

var
  { Asset variables }
  texDosuEXE: array[0..1] of TTexture;

  { Game state variables }
  t: double;


procedure OnPreload; far;
begin
  LoadTex(texDosuEXE[0], 'IMG/DOSU_1.BMP');
  LoadTex(texDosuEXE[1], 'IMG/DOSU_2.BMP');
end;

procedure OnReady; far;
begin
  t := 0.0;
end;

procedure OnCleanup; far;
begin
  FreeTex(texDosuEXE[0]);
  FreeTex(texDosuEXE[1]);
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
    Spr(texDosuEXE[0], 148, 76)
  else
    Spr(texDosuEXE[1], 148, 76);

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

