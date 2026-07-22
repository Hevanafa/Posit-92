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
  a, b: word;
  startTime, diff: double;
  image: PBitmap;
  imgWidth: word;
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

  { pascalRectfillDither(10, 10, 110, 110, 15); }
  { asmRectfillDither(10, 10, 110, 110, 15); }
  { asmRectfillDither(random(320), random(320), random(200), random(200), 1 + random(15)); }

  image := dosuEXE[0];
  asm
    les bx, image
    mov dx, es:[bx]
    mov imgWidth, dx
  end;
  writeLog('Width: ' + i32str(imgWidth));
  
  for b:=1 to 9 do
  for a:=1 to 15 do
    { 135 ops: 0.0235s }
    { pascalCirc(a * 20, b * 20, 10, 15); }

    { 135 ops: 0.0108s }
    { asmCirc2(a * 20, b * 20, 10, 15); }
    { 0.0948s }
    { pascalCircfill(a * 20, b * 20, 10, 15); }
    { 0.0116s }
    { asmCircfill(a * 20, b * 20, 10, 15); }

    { pascalVline(random(320), random(200), random(200), 1 + random(14)); }
    { asmVline2(random(320), random(200), random(200), 1 + random(14)); }

    { pascalRect(a * 20, b * 20, a * 20 + 10, b * 20 + 10, 15); }
    { asmRect(a * 20, b * 20, a * 20 + 10, b * 20 + 10, 15); }
    { asmRect2(a * 20, b * 20, a * 20 + 10, b * 20 + 10, 15); }

    { pascalDrawBMP(dosuEXE[0], a * 20, b * 20); }
    { asmDrawBMP(dosuEXE[0], a * 20, b * 20); }
    asmSpr(dosuEXE[0], a * 20, b * 20, 13);


  { Full test }
  { for a:=1 to 1000 do begin }
    { 3.4140s, 3.0970s, 3.3225s }
    { pascalRectfillDither(random(320), random(320), random(200), random(200), random(16)); }
    { unoptimised asm: 3.8478s, 3.7312s }
    { 1.8877s, 1.7040s, 1.7772s }
    { asmRectfillDither(random(320), random(320), random(200), random(200), 1 + random(15)); }

    { 0.0678s, 0.0680s, 0.0681s }
    { pascalCirc(random(320), random(200), 10, 1 + random(14)); }
    { 0.0298s, 0.0294s, 0.0300s }
    { asmCirc(random(320), random(200), 10, 1 + random(14)); }

    { 0.0678s, 0.0680s, 0.0681s }
    { pascalCircfill(random(320), random(200), 10, 1 + random(14)); }
    { 0.0363s }
    { asmCircfill(random(320), random(200), 10, 1 + random(14)); }

    { 0.0692s, 0.0811s, 0.0732s }
    { pascalVline(random(320), random(200), random(200), 1 + random(14)); }

    { 0.0217s, 0.0168s, 0.0188s }
    { asmVline(random(320), random(200), random(200), 1 + random(14)); }
    { 0.0106s, 0.0113s, 0.0119s }
    { asmVline2(random(320), random(200), random(200), 1 + random(14)); }

    { 0.4295s, 0.3799s, 0.3876s }
    { pascalRect(random(320), random(200), random(320), random(200), 1 + random(14)); }
    { 0.1514s, 0.1456s, 0.1466s }
    { asmRect(random(320), random(200), random(320), random(200), 1 + random(14)); }
    { 0.0782s, 0.0708s, 0.0721s }
    { asmRect2(random(320), random(200), random(320), random(200), 1 + random(14)); }

    { pascalDrawBMP(dosuEXE[0], random(320), random(200)); }
    { asmDrawBMP(dosuEXE[0], random(320), random(200)); }
    { asmSpr(dosuEXE[0], random(320), random(200), 13); }
  { end; }

  diff := getTimer - startTime;

  { Small test }
  { print(i32str(9 * 15) + ' operations done in ' + f32str(diff) + 's', 0, 0, 15); }
  { Full test }
  print('1000 operations done in ' + f32str(diff) + 's', 0, 0, 15);
  
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
