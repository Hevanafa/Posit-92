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

  asm
    mov eax, 0
  end;

  {
  repeat
    update;
    draw
  until done;
  }

  cls($00);
  startTime := getTimer;

  { Real test }
  for a:=0 to 1000 do
    { asmHline: 0.0680s, 0.0698s, 0.0714s }
    { asmHline(random(320), random(320), random(200), random(16)); }
    { asmHline2 (stosw): 0.0167s, 0.0168s, 0.0167s }
    asmHline2(random(320), random(320), random(200), random(16));

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
