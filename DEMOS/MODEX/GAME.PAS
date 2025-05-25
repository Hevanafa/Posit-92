
uses
  CRT,
  ModeX, Logger;

var
  done: boolean;

procedure INIT;
begin
  initLogger;
  initModeX;

  randomize;
end;


procedure update;
begin
  { updateDeltaTime;
  updateMouse;
  }

  { if isKeyDown(K_ESC) then done := true; }
  { t:=t+dt }
end;


procedure draw;
begin
  cls($7D);

  { print('Hello world!', 160-48, 120, 15); }
  { drawMouse; }
  { flush }
end;

var
  a, b: integer;
begin
  INIT;
  done := false;

  for b:=0 to 239 do
  for a:=0 to 79 do
    PSET(a, b, a);

  flipPages;

  readLn;

  {
    Might show an incomplete pattern due to the uninitialised video page.
    This is because the memory contains the leftover data from previous
    operations
  }
  { setDisplayPage(1); }

  {
  repeat
    update;
    draw
  until done;
  }

  {
  resetMouse;
  resetKeyHandler;
  }
  { freeBuffer;
  closeLogger; }
  initTextMode
end.
