
uses
  CRT,
  Bitmap, Conv, Logger, Mouse, VGA;

var
  done: boolean;
  kenneyTinytown: PBitmap;
  lastX, lastY: word;
  colour: byte;


function PGET(const x, y: integer): byte;
var
  offset: integer;
begin
  if (x < 0) or (x >= 320) or (y < 0) or (y >= 200) then begin
    PGET := 0;
    exit
  end;
  offset := y * 320 + x;
  PGET := Mem[$A000:offset]
end;

procedure INIT;
begin
  randomize;
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initMouse;

  loadBMP(kenneyTinytown, 'IMG/TINYTOWN.BMP');
end;


procedure update;
var
  a: integer;
  ch: char;
begin
  updateMouse;
  
  if (lastX <> mouseX) or (lastY <> mouseY) then begin
    lastX := mouseX;
    lastY := mouseY;
    colour := PGET(mouseX, mouseY);
  end;
  
  if keyPressed then begin
    ch := readKey;
    if ch = #27 then done := true;
  end;
end;


procedure draw;
begin
  cls($7D);  
  
  drawBMP(kenneyTinytown);
  print('Colour: ' + i32str(colour), 4, 4, 15);
  
  drawMouse;
  flush
end;


begin
  INIT;
  done := false;

  repeat
    update;
    draw
  until done;

  freeBMP(kenneyTinytown);
  resetMouse;
  freeBuffer;
  closeLogger;
  initTextMode
end.
