{
  Frame skip demonstration
}

uses
  CRT,
  Logger, FPS, Mouse, Timing, VGA,
  Bitmap;

const
  TARGET_FPS = 35;
  MAX_FRAME_SKIP = 5;
var
  done: boolean;
  startTime, nextGameTick: double;
  loops: word;
  DosuEXE: array[0..1] of PBitmap;


procedure INIT;
begin
  randomize;
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initMouse;
  initFPSCounter;

  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;


procedure update;
var
  a: integer;
begin
  updateDeltaTime;
  updateMouse;
  incrementFPS;

  if keyPressed then
    if readKey = #27 then done := true;
end;


procedure draw;
var
  a: integer;
  t: double;
begin
  cls($7D);

  t := getTimer - startTime;

  if (trunc(t * 1.5) and 1) = 0 then
    spr(dosuEXE[0], 148, 76, 13)
  else
    spr(dosuEXE[1], 148, 76, 13);

  drawMouse;
  drawFPS;
  flush
end;


begin
  INIT;
  startTime := getTimer;
  done := false;
  nextGameTick := getTimer;

  repeat
    loops := 0;

    while (getTimer > nextGameTick) and (loops < MAX_FRAME_SKIP) do begin
      update;
      nextGameTick := nextGameTick + (1 / TARGET_FPS);
      inc(loops)
    end;

    draw
  until done;

  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);

  resetMouse;
  freeBuffer;
  closeLogger;
  initTextMode
end.
