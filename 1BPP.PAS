
uses
  CRT, DOS,
  Logger, Keyboard, Mouse, Timing, VGA,
  Bitmap;
  { Conv, FPS, Graphics, PCS; }

const
  K_ESC = $01;
var
  done: boolean;
  t: double;
  cursor: PMonoBitmap;
  playdate: PMonoBitmap;
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

  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
  loadMonoBMP(cursor, 'CUR1BPP.BMP');
  loadMonoBMP(playdate, 'PLAYDATE.BMP');
end;


procedure drawMouseMono;
begin
  sprMono(cursor, mouseX, mouseY);
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

  { TODO: Your drawing code here }
  sprMono(playdate, 0, 0);

  if (trunc(t * 1.5) and 1) = 0 then
    spr(dosuEXE[0], 148, 76, 13)
  else
    spr(dosuEXE[1], 148, 76, 13);

  print('Hello world!', 160-48, 120, 15);

  drawMouseMono;

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
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
