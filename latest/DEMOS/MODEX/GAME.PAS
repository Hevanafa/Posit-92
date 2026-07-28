{
  Mode X demo
  Requires P92_MODEX custom directive enabled
}

{$DEFINE DEBUG}

uses
  CRT,
  P92Core, P92Mouse, Conv, Logger, Timing, ModeX, XBitmap;

procedure Update; far;
begin
  if keyPressed and (readKey = #27) then SignalDone;
end;


procedure Draw; far;
begin
  cls($7D);

  { print('getTimer:' + f32str(getTimer), 0, 20, 15); }
  print('Top area', 0, 20, 15);
  print('Hello world!', 160-48, 120, 15);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.EnableKeyHandler := false;

  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;

  P92Start(appConfig)
end.

