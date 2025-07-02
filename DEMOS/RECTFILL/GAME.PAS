{$DEFINE DEBUG}

uses
  CRT, DOS,
  Bitmap, Conv, Graphics,
  Logger, Mouse, Timing, VGA;

const
  SC_ESC = $01;
var
  done: boolean;
  t: double;
  DosuEXE: array[0..1] of PBitmap;
  { TODO: More of your game state here }


procedure INIT;
begin
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initMouse;

  { TODO: Your init code here }

  randomize;
  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;


procedure update;
begin
  updateDeltaTime;
  updateMouse;

  { TODO: Your update code here }

  if keyPressed then if readKey = #27 then done := true;
  
  t:=t+dt
end;


procedure draw;
begin
  cls($7D);

  { TODO: Your drawing code here }

  if (trunc(t * 1.5) and 1) = 0 then
    spr(dosuEXE[0], 148, 76, 13)
  else
    spr(dosuEXE[1], 148, 76, 13);

  print('Hello world!', 160-48, 120, 15);
  drawMouse;

  flush
end;


var
  a: word;
  startTime, diff: double;
begin
  INIT;
  done := false;

  {
  repeat
    update;
    draw
  until done;
  }
  cls($00);
  startTime := getTimer;

  { for a:=0 to 1000 do }
  {
  asmRectfill2(0, 10, 10, 20, 9);
  asmRectfill2(0, 30, 9, 40, 9);
  }
  { Handle edge cases }
  {
  asmRectfill2(-10, 10, 10, 20, 9);
  asmRectfill2(310, 10, 320, 20, 9);
  }
  { asmRectfill2(10, -10, 20, 10, 9); }
  { asmRectfill2(10, 190, 20, 210, 9); }

  {
  asmRectfill2(-10, -10, 10, 10, 9);
  asmRectfill2(310, 190, 330, 210, 9);
  }

  { Real test }
  for a:=0 to 1000 do
    { 4.2s, 3.8697s, 3.9519s }
    { pascalRectfill(random(320), random(200), random(320), random(200), random(16)); }
    { 3.8307s, 3.8898s, 4.0777s }
    { Removed bounds check: 2.9446, 2.9429s }
    { stosw: 0.1867s, 0.1724s, 0.1865s }
    asmRectfill2(random(320), random(200), random(320), random(200), random(16));

  diff := getTimer - startTime;

  print('1000 operations done in ' + f32str(diff) + 's', 0, 0, 7);
  flush;

  readLn;

  { TODO: Your cleanup code here }
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);

  resetMouse;
  freeBuffer;
  closeLogger;
  initTextMode
end.
