{
  Basic mouse implementation
}

uses
  CRT,
  P92Core, Conv, P92Mouse, P92VGA;


procedure Update; far;
begin
  if keyPressed and (ReadKey = #27) then SignalDone;
end;

procedure Draw; far;
begin
  cls($7D);

  print('Mouse', 32, 24, 15);
  print('x: ' + I32Str(mouseX), 32, 32, 15);
  print('y: ' + I32Str(mouseY), 32, 40, 15);
  print('Button: ' + I32Str(mouseButton), 32, 56, 15);
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

