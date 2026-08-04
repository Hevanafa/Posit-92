{
  Mode X demo
  Part of Posit-92 game engine

  Requires P92_MODE_X custom directive enabled in Turbo Pascal:
  1. Options menu > Compiler...
  2. Conditional defines

  Also, all the TPU files must be cleaned up first
  since stale units may have the version without P92_MODEX enabled
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

