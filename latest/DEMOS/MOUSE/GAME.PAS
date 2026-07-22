{
  Basic mouse implementation
}

uses
  CRT,
  Bitmap, Conv, Logger, Mouse, VGA;

var
  done: boolean;

procedure INIT;
begin
  randomize;
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initMouse;
end;


procedure update;
var
  a: integer;
  ch: char;
begin
  updateMouse;
  
  if keyPressed then begin
    ch := readKey;
	if ch = #27 then done := true;
  end;
end;


procedure draw;
var
  a: integer;
begin
  cls($7D);

  print('Mouse', 32, 24, 15);
  print('x: ' + i32str(mouseX), 32, 32, 15);
  print('y: ' + i32str(mouseY), 32, 40, 15);
  print('Button: ' + i32str(mouseButton), 32, 56, 15);
  
  drawMouse;
  flush
end;


begin
  INIT;
  done := false;

  repeat
    update;
    draw;
  until done;

  resetMouse;
  freeBuffer;
  closeLogger;
  initTextMode
end.
