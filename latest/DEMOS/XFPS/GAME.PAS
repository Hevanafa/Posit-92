{$DEFINE DEBUG}

uses
  P92Core, Conv, Logger, Timing, Keyboard,
  ModeX, XBitmap, XMouse, XFPS;

procedure Update; far;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;
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

  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;

  P92Start(appConfig)
end.

