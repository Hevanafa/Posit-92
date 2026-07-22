{
  Basic mouse implementation
}

uses
  CRT,
  Bitmap, Conv, Logger, Mouse, VGA;

var
  done: boolean;

procedure Init;
begin
  Randomize;

  InitLogger;
  InitVGAMode;
  LoadFont;
  InitBuffer;
  InitMouse;
end;


procedure Update;
var
  a: integer;
  ch: char;
begin
  UpdateMouse;
  
  if keyPressed then begin
    ch := readKey;
	if ch = #27 then done := true;
  end;
end;


procedure Draw;
var
  a: integer;
begin
  cls($7D);

  print('Mouse', 32, 24, 15);
  print('x: ' + i32str(mouseX), 32, 32, 15);
  print('y: ' + i32str(mouseY), 32, 40, 15);
  print('Button: ' + i32str(mouseButton), 32, 56, 15);
  
  DrawMouse;

  Flush
end;


begin
  Init;
  done := false;

  repeat
    Update;
    Draw;
  until done;

  ResetMouse;
  FreeBuffer;
  CloseLogger;
  InitTextMode
end.
