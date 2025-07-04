{$DEFINE DEBUG}

uses
  CRT, DOS,
  Bitmap, Conv, Logger, Keyboard, Mouse,
  Panic, Timing, VGA,
  BMPRLE;

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
  initKeyHandler;
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

  if isKeyDown(SC_ESC) then done := true;
  
  t:=t+dt
end;


procedure draw;
begin
  cls($7D);

  { TODO: Your drawing code here }

  if (trunc(t * 1.5) and 1) = 0 then
    asmDrawBMP(dosuEXE[0], 148, 76)
  else
    asmDrawBMP(dosuEXE[1], 148, 76);

  print('Hello world!', 160-48, 120, 15);
  drawMouse;

  flush
end;


var
  a: word;
  startTime, diff: double;
  image: PBitmap;
  sampleRLE: PRLEBitmap;
begin  
  { writeLn('Hello!'); }
  loadBMP(image, 'IMG/DOSU_1.BMP');

  convertToRLE(image, sampleRLE);

  {
  a:=0; x:=0;
  while a < sampleRLE^.dataSize do begin
    count := sampleRLE^.data[a];
    write('[', count, ', ', sampleRLE^.data[a+1], '], ');

    inc(x, count);
    if x >= sampleRLE^.width then begin
      x := 0;
      writeLn;
    end;
    inc(a, 2)
  end;
  }

  readLn;

  initVGAMode;
  initBuffer;
  loadFont;

  cls($00);

  { blitRLE(sampleRLE, 10, 10); }

  { Edge cases }
  { blitRLE(sampleRLE, -10, -10);
  blitRLE(sampleRLE, 10, -10); }

  { blitRLE(sampleRLE, -10, 10);
  blitRLE(sampleRLE, 310, 10); }

  { blitRLE(sampleRLE, 10, 190); }
  { blitRLEUnsafe(sampleRLE, 10, 10); }

  startTime := getTimer;
  for a:=1 to 1000 do begin
    { 1.5595s }
    { pascalDrawBMP(image, random(320), 10 + random(190)); }
    { 0.5694s }
    { blitRLE(sampleRLE, random(320), 10 + random(190), 13); }

    { 1.5592s }
    { pascalSpr(image, random(320), random(200), 13); }
    { 0.5352s }
    blitRLE2(sampleRLE, random(320), 10 + random(190), 13);
  end;
  diff := getTimer - startTime;

  print('1000 operations done in ' + f32str(diff) + 's', 0, 0, 15);

  flush;

  readLn;

  initTextMode;

  freeRLEBitmap(sampleRLE);
  freeBMP(image);

  exit;

  INIT;
  done := false;
  startTime := getTimer;

  repeat
    update;
    draw
  until done;

  { TODO: Your cleanup code here }
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);

  resetMouse;
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
