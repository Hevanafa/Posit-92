{
  Show remaining memory demo
}

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92Core, Logger, P92VGA, P92MEM;

procedure Update; far;
begin
  if KeyPressed and (ReadKey = #27) then SignalDone;
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

