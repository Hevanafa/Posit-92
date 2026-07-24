{
  Show remaining memory demo
}

uses
  CRT, DOS,
  P92Core, Logger, VGA, Memory;

procedure Update; far;
var
  c: char;
begin
  if KeyPressed then begin
    c := ReadKey;
    if c = #27 then SignalDone;
  end;
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
  appConfig.EnableKeyHandler := false;

  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;

  P92Start(appConfig)
end.

