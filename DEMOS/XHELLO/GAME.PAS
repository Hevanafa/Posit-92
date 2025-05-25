
uses
  CRT,
  ModeX, Logger;

var
  done: boolean;

procedure INIT;
begin
  initLogger;
  initModeX;
  loadFont;

  randomize;
end;


procedure update;
begin
  { updateDeltaTime;
  updateMouse;
  }

  if keyPressed then if readKey = #27 then done := true;
end;


procedure draw;
begin
  cls($7D);

  print('Hello world!', 160-48, 120, 15);
  { drawMouse; }
end;

var
  a, b: integer;
begin
  INIT;
  done := false;

  repeat
    update;
    draw;
    flipPages  { this reduces flickering }
  until done;

  {
    Might show an incomplete pattern due to the uninitialised video page.
    This is because the memory contains the leftover data from previous
    operations
  }

  {
  resetMouse;
  resetKeyHandler;
  }

  closeLogger;
  initTextMode
end.
