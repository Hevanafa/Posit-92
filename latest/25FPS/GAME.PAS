{$DEFINE DEBUG}

uses
  CRT, DOS,
  Bitmap, FPS, Logger, Keyboard, Mouse, Timing, VGA;

const
  SC_ESC = $01;
var
  done: boolean;
  t: double;
  DosuEXE: array[0..1] of PBitmap;
  { TODO: More of your game state here }


procedure INIT;
begin
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initKeyHandler;
  initMouse;
  initFPSCounter;

  { TODO: Your init code here }

  randomize;
  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;


procedure update;
begin
  updateDeltaTime;
  updateMouse;
  { incrementFPS; }

  { TODO: Your update code here }

  if isKeyDown(SC_ESC) then done := true;
  
  t:=t+dt
end;


procedure draw;
begin
  cls($7D);

  { TODO: Your drawing code here }

  if (trunc(t * 1.5) and 1) = 0 then
    spr(dosuEXE[0], 148, 76, 13)
  else
    spr(dosuEXE[1], 148, 76, 13);

  print('Hello world!', 160-48, 120, 15);
  drawMouse;
  drawFPS;

  flush
end;


var
  now,
  nextUpdateTick,
  nextDrawTick: double;
  
begin
  INIT;
  done := false;

  now := getTimer;
  nextUpdateTick := now;
  nextDrawTick := now;

  repeat
    now := getTimer;
    incrementFPS;

    if now >= nextUpdateTick then begin
      nextUpdateTick := now + 1.0 / 20.0;
      update
    end;

    if now >= nextDrawTick then begin
      nextDrawTick := now + 1.0 / 60.0;
      draw
    end;
  until done;

  { TODO: Your cleanup code here }
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);

  resetMouse;
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
