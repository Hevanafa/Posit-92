
uses CRT, Logger, Maths, Mouse, VGA;

const
  K_ESC = $01;
var
  done: boolean;


procedure rectfillDither(x0, y0, x1, y1: integer; const colour: byte);
var
  a, b, temp: integer;
begin
  if x0 > x1 then begin
    temp := x0; x0 := x1; x1 := temp
  end;
  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;

  x0:=trunc(max(x0, 0));   y0:=trunc(max(y0,0));
  x1:=trunc(min(x1, 319)); y1:=trunc(min(y1,199));

  for b:=y0 to y1 do
    for a:=x0 to x1 do
      if (a+b) and 1 = 1 then
        surface^[b*320+a] := colour;
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
