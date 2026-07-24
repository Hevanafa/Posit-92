{$DEFINE DEBUG}

uses
  CRT,
  Conv, Logger, Timing, ModeX, XBitmap, XFPS, XMouse;

var
  done: boolean;

procedure INIT;
begin
  initLogger;
  initModeX;
  loadFont;
  initMouse;

  initDeltaTime;
  initFPSCounter;

  randomize;
end;


procedure update;
begin
  updateDeltaTime;
  updateMouse;
  incrementFPS;

  if keyPressed then if readKey = #27 then done := true;
end;


procedure draw;
begin
  cls($7D);

  { print('getTimer:' + f32str(getTimer), 0, 20, 15); }
  print('Top area', 0, 20, 15);
  print('Hello world!', 160-48, 120, 15);
  
  { Might disappear due to screen tearing, often happens in slower CPU's }
  drawMouse;
  drawFPS
end;

var
  a, b: integer;
begin
  INIT;
  done := false;

  repeat
    limit(35);
    update;
    draw;
    flipPages
  until done;

  resetMouse;
  closeLogger;
  initTextMode
end.
