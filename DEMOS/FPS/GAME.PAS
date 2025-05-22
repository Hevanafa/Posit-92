{
  FPS unit usage demo
  Requires both the Timing & the FPS units initialised in order
}

uses
  CRT, FPS, Timing, VGA;

var
  done: boolean;

procedure INIT;
begin
  initVGAMode;
  loadFont;
  initBuffer;
  { Required: }
  initDeltaTime;
  initFPSCounter;
end;


procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  if keyPressed then
    if readKey = #27 then done := true;
end;


procedure draw;
begin
  cls($7D);
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

  freeBuffer;
  initTextMode
end.
