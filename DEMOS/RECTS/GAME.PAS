{
  Rect demo
  Referenced from https://github.com/nesbox/TIC-80/wiki/rect
}

uses CRT, Graphics, FPS, Logger, Timing, VGA;

var
  done: boolean;
  x, y, dx, dy, colour: integer;

procedure INIT;
begin
  randomize;
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initFPSCounter;
  
  dx := 7;
  dy := 4;
  colour := 1;
end;


procedure update;
var
  a: integer;
  ch: char;
begin
  updateDeltaTime;
  incrementFPS;
  
  inc(x, dx);
  inc(y, dy);
  
  { Check screen walls }
  if (x>320-6) or (x<0) then begin
    dx := -dx;
    colour := colour mod 15 + 1
  end;
  
  if (y>200-6) or (y<0) then begin
    dy := -dy;
    colour := colour mod 15 + 1
  end;

  if keyPressed then begin
    ch := readKey;
    if ch = #27 then done := true;
  end;
  
end;


procedure draw;
var
  a: integer;
  ch: char;
begin
  { cls($7D); }
  rectfill(x, y, x+5, y+5, colour);
  
  rectfill(240, 0, 302, 8, 0);
  drawFPS;
  
  flush
end;


begin
  INIT;
  done := false;

  cls($7D);
  repeat
    update;
    draw
  until done;

  freeBuffer;
  closeLogger;
  initTextMode
end.
