
uses
  CRT, DOS,
  P92Core, Logger, FPS, P92KBD, P92Mouse, Timing, P92VGA,
  MonoTex;

var
  { Asset variables }
  cursor: PMonoTexture;
  playdate: PMonoTexture;

  { Game state variables }
  t: double;


procedure OnPreload; far;
begin
  LoadMonoTex(cursor, 'CUR1BPP.BMP');
  LoadMonoTex(playdate, 'PLAYDATE.BMP');
end;

procedure OnCleanup; far;
begin
  FreeMonoTex(cursor);
  FreeMonoTex(playdate);
end;

procedure OnReady; far;
begin
  t := 0.0
end;

procedure drawMouseMono;
begin
  SprMono(cursor, mouseX, mouseY, $0C)
end;


procedure Update; far;
begin
  if isKeyDown(SC_ESCAPE) then SignalDone;

  t:=t+DeltaTime;
end;


procedure Draw; far;
begin
  cls($7D);

  SprMono(playdate, 9, 4, 15);
  print('Hello world!', 160-48, 136, $7D);
  debugMouse;
  drawMouseMono;
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.LoadDefaultCursor := false;
  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

