
uses CRT, Logger, Mouse, VGA;

const
  K_ESC = $01;
var
  done: boolean;
  { TODO: More of your game state here }


procedure rectfillDither(x0, y0, x1, y1: integer; colour: byte);
var
  a, b, temp: integer;
begin
  if x0 > x1 then begin
    temp := x0; x0 := x1; x1 := temp
  end;
  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;
  for b:=y0 to y1 do
    for a:=x0 to x1 do
      if (a+b) and 1 = 1 then
        pset(a, b, colour);
end;

procedure INIT;
begin
  randomize;
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initMouse;
end;


procedure update;
begin
  updateMouse;

  if keyPressed then
    if readKey = #27 then done := true;
end;


procedure draw;
begin
  cls($7D);
  rectfillDither(10, 20, 50, 60, 7);
  drawMouse;
  flush
end;


begin
  INIT;
  done := false;

  repeat
    update;
    draw;
  until done;

  { Clean-up }
  resetMouse;
  freeBuffer;
  closeLogger;
  initTextMode
end.
