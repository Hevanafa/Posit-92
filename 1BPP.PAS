
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

  loadMonoBMP(cursor, 'CUR1BPP.BMP');
  loadMonoBMP(playdate, 'PLAYDATE.BMP');
end;


procedure drawMouseMono;
begin
  { sprMono(cursor, mouseX, mouseY); }
  sprMonoTint(cursor, mouseX, mouseY, $0C)
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
  sprMono(playdate, 9, 4);
  print('Hello world!', 160-48, 136, $7D);
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

  freeMonoBMP(cursor);
  freeMonoBMP(playdate);

  resetMouse;
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
