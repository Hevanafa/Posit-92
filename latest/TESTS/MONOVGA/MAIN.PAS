
uses
  P92VGA;

begin
  LoadCGAFont;

  InitBuffer(320, 200);
  InitMode13h;

  cls($00);
  print('Hello from MonoVGA!', 8, 8, $07);
  PresentMode13h;

  readln;

  FreeBuffer;
  InitModeText;
end.
