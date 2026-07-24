{
  Show remaining memory demo
}

uses
  CRT, DOS,
  P92Core, Logger, Keyboard, VGA, Memory;

procedure Update; far;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;
end;


procedure Draw; far;
begin
  cls($7D);

  drawMemInfo;
  drawDOSMemInfo;
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.LoadDefaultCursor := false;

  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;

  P92Start(appConfig)
end.

