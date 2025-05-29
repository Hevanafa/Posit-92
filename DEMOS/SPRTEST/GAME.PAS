
uses
  CRT, DOS,
  Bitmap, Conv, Graphics, Logger, Mouse, Timing, VGA;

const
  K_ESC = $01;
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


var
  a, x, y: integer;
  startTime: double;
begin
  INIT;
  done := false;

  cls($7D);
  startTime := getTimer;

  {
  for a:=0 to 1000 do
    spr(dosuEXE[0], random(300), random(180), 13);
  }

  { for a:=1 to 1000 do begin
    x := random(300);
    y := random(180); }

    { TODO: This only works once }
    { fastSpr4(dosuEXE[0], x, y, 13); }
    { fastSpr5(dosuEXE[0], x, y, 13); }
    { print(i32str(a), x, y, 15); }
  { end; }

  { fastSpr5(dosuEXE[0], 100, 50, 13);
  fastSpr5(dosuEXE[0], 150, 50, 13); }

  {
  spr(dosuEXE[0], 150, 50, 13);
  }

  { asmSprUnsafe(dosuEXE[0], 150, 50, 13); }
  for a:=1 to 1000 do begin
    x := random(300);
    y := random(180);
    asmSprSafe(dosuEXE[0], x, y, 13);
  end;



  { Black rectangle behind the text below }
  rectfill(0, 0, 240, 8, 0);
  print('1000 operations done in ' + f32str(getTimer - startTime) + 's', 0, 0, 15);

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
