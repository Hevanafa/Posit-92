
uses
  CRT, DOS,
  Logger, Keyboard, Mouse, Timing, VGA;
  { Conv, FPS, Graphics, PCS; }

const
  K_ESC = $01;
var
  done: boolean;
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
end;


procedure update;
var
  a: integer;
begin
  updateDeltaTime;
  updateMouse;

  { TODO: Your update code here }

  if isKeyDown(K_ESC) then done := true;
end;


procedure draw;
var
  a: integer;
begin
  cls(1);

  { TODO: Your drawing code here }
  { TODO: Make this similar to TIC-80 }

  drawMouse;

  flush
end;


var
  a: integer;

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
