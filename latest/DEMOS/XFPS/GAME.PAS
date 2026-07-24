{$DEFINE DEBUG}

uses
  Conv, Logger, Timing,
  Keyboard, XMouse,
  ModeX, XBitmap, XFPS;

procedure Update; far;
begin
  if keyPressed then if readKey = #27 then done := true;
end;

procedure Draw; far;
begin
  cls($7D);

  { print('getTimer:' + f32str(getTimer), 0, 20, 15); }
  print('Top area', 0, 20, 15);
  print('Hello world!', 160-48, 120, 15);
  
  { Might disappear due to screen tearing, often happens in slower CPU's }
  drawMouse;
  drawFPS
end;

var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.EnableModeX := true;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

