
uses
  CRT, DOS,
  Logger, Keyboard, Mouse, Timing, VGA,
  Bitmap;

const
  K_ESC = $01;
var
  done: boolean;
  t: double;
  DosuEXE: array[0..1] of PBitmap;
  { TODO: More of your game state here }


procedure INIT;
begin
  randomize;
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initKeyHandler;
  initMouse;

  { TODO: Your init code here }

  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;


procedure update;
var
  a: integer;
begin
  updateDeltaTime;
  updateMouse;

  { TODO: Your update code here }

  if isKeyDown(K_ESC) then done := true;
  t:=t+dt
end;


procedure draw;
var
  a: integer;
begin
  cls($7D);

  if (trunc(t * 1.5) and 1) = 0 then
    tic80spr(dosuEXE[0], 96, 24, 13, 2)
  else
    tic80spr(dosuEXE[1], 96, 24, 13, 2);

  print('Hello world!', (240-96) div 2, 84, 15);
  drawMouse;
  tic80Flush
end;


begin
  INIT;
  done := false;

  repeat
    update;
    draw;
  until done;

  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);

  resetMouse;
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
