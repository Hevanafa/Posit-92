
uses
  CRT, DOS,
  Logger, FPS, Keyboard, Mouse, Timing, VGA,
  MonoBMP;

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
  initFPSCounter;

  loadMonoBMP(cursor, 'CUR1BPP.BMP');
  loadMonoBMP(playdate, 'PLAYDATE.BMP');
end;


procedure drawMouseMono;
begin
  sprMono(cursor, mouseX, mouseY, $0C)
end;


procedure update;
var
  a: integer;
begin
  updateDeltaTime;
  updateMouse;
  incrementFPS;

  if isKeyDown(K_ESC) then done := true;
  t:=t+dt
end;


procedure draw;
var
  a: integer;
begin
  cls($7D);
  { sprMono(playdate, 9, 4, 15); }
  print('Hello world!', 160-48, 136, $7D);
  debugMouse;
  drawMouseMono;
  drawFPS;
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
