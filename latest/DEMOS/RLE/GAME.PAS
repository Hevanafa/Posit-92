{$DEFINE DEBUG}

uses
  CRT, DOS,
  P92Core, Bitmap, Conv, Logger, Keyboard, Mouse,
  Panic, Timing, VGA,
  BMPRLE;

var
  { Asset variables }
  image: PBitmap;
  sampleRLE: PRLEBitmap;
  DosuEXE: array[0..1] of PBitmap;

  { Game state variables }
  t: double;
  a: word;
  startTime, diff: double;


procedure OnPreload; far;
begin
  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;

procedure OnCleanup; far;
begin
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);

  freeRLEBitmap(sampleRLE);
  freeBMP(image);
end;

procedure OnReady; far;
begin

end;

procedure Update; far;
begin
  if isKeyDown(SC_ESCAPE) then SignalDone;
  
  t:=t+DeltaTime;
end;


procedure Draw; far;
begin
  cls($7D);

  { TODO: Your drawing code here }

  if (trunc(t * 1.5) and 1) = 0 then
    asmDrawBMP(dosuEXE[0], 148, 76)
  else
    asmDrawBMP(dosuEXE[1], 148, 76);

  print('Hello world!', 160-48, 120, 15);
end;


var
  appConfig: TP92AppConfig;
begin
  loadBMP(image, 'IMG/DOSU_1.BMP');

  convertToRLE(image, sampleRLE);

  initLogger;
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
    { 0.5962s }
    { asmSpr(image, random(320), 10 + random(190), 13) }
    { 0.5352s }
    blitRLE2(sampleRLE, random(320), 10 + random(190), 13);
  end;
  diff := getTimer - startTime;

  print('1000 operations done in ' + f32str(diff) + 's', 0, 0, 15);

  flush;

  readln;
  exit;

  DefaultP92AppConfig(appConfig);

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

