{
  100 spr demo
}

uses
  CRT, DOS,
  Bitmap, Logger, FPS, Timing, VGA;

type
  TVec2 = record
    x, y: double;
  end;

var
  done: boolean;
  imgGrass: PBitmap;
  positions: array[0..99] of TVec2;


procedure INIT;
var
  a: integer;
begin
  randomize;
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initFPSCounter;

  loadBMP(imgGrass, 'IMG\GRASS.BMP');
  
  for a:=0 to high(positions) do
    with positions[a] do begin
	  x := trunc(random(300));
	  y := trunc(random(180))
    end;
end;


procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  if keyPressed then
    if readKey = #27 then done := true;
end;


procedure draw;
var
  a: integer;
begin
  cls($7D);
  
  for a:=0 to high(positions) do
    spr(imgGrass, trunc(positions[a].x), trunc(positions[a].y), 13);

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

  freeBMP(imgGrass);

  freeBuffer;
  closeLogger;
  initTextMode
end.
