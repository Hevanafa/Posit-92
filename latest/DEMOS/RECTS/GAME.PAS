{
  Rect demo
  Referenced from https://github.com/nesbox/TIC-80/wiki/rect
}

uses
  P92Core, Graphics, FPS, Logger, Timing, VGA;

var
  done: boolean;
  x, y, dx, dy, colour: integer;

procedure OnReady; far;
begin
  dx := 7;
  dy := 4;
  colour := 1;
end;


procedure Update; far;
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


procedure Draw; far;
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


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

