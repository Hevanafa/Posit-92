{$DEFINE DEBUG}

uses
  P92Core, Conv, Logger, FPS, Timing,
  Keyboard, Mouse,
  ModeX, XBitmap;

procedure Update; far;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;
end;

procedure Draw; far;
begin
  Cls($7D);

  { Print('getTimer:' + f32str(getTimer), 0, 20, 15); }
  Print('Top area', 0, 20, $0F);
  Print('Hello from VGA Mode X!', 160-48, 120, $0E);
end;

var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;

  P92Start(appConfig)
end.

