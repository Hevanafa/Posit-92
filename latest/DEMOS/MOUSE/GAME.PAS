{
  Basic mouse implementation
}

uses
  CRT,
  P92Core, Conv, Mouse, VGA;


procedure Update; far;
begin
  if keyPressed and (ReadKey = #27) then SignalDone;
end;

procedure Draw; far;
begin
  cls($7D);

  print('Mouse', 32, 24, 15);
  print('x: ' + i32str(mouseX), 32, 32, 15);
  print('y: ' + i32str(mouseY), 32, 40, 15);
  print('Button: ' + i32str(mouseButton), 32, 56, 15);
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

