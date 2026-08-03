uses
  CRT, DOS,
  P92Core, P92TEX, Conv, Logger, P92KBD, P92Mouse, Panic, Timing, P92VGA, BMPRLE;

var
  { Asset variables }
  image: TTexture;
  sampleRLE: TRLETexture;
  DosuEXE: array[0..1] of TTexture;

  { Game state variables }
  t: double;
  a: word;
  startTime, diff: double;


procedure OnPreload; far;
begin
  LoadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  LoadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;

procedure OnCleanup; far;
begin
  FreeBMP(dosuEXE[0]);
  FreeBMP(dosuEXE[1]);
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
    Spr(dosuEXE[0], 148, 76)
  else
    Spr(dosuEXE[1], 148, 76);

  SprRLEOpaque(sampleRLE, 178, 76);

  print('Hello world!', 160-48, 120, 15);
end;


var
  appConfig: TP92AppConfig;
begin
  LoadBMP(image, 'IMG/DOSU_1.BMP');

  ConvertToRLE(image, sampleRLE);

  InitLogger;
  InitMode13h;
  InitBuffer(DefaultVGAWidth, DefaultVGAHeight);
  LoadCGAFont;

  cls($00);

  { SprRLEOpaque(sampleRLE, 10, 10); }

  { Edge cases }
  { SprRLEOpaque(sampleRLE, -10, -10);
  SprRLEOpaque(sampleRLE, 10, -10); }

  { SprRLEOpaque(sampleRLE, -10, 10);
  SprRLEOpaque(sampleRLE, 310, 10); }

  { SprRLEOpaque(sampleRLE, 10, 190); }
  { UnsafeSprRLE(sampleRLE, 10, 10); }

  startTime := getTimer;
  for a:=1 to 1000 do begin
    { 1.5595s }
    { pascalDrawBMP(image, random(320), 10 + random(190)); }
    { 0.5694s }
    { SprRLEOpaque(sampleRLE, random(320), 10 + random(190), 13); }

    { 0s }
    { pascalSpr(image, random(320), random(200), 13); }
    { 0.9467s }
    SprRLEOpaque(sampleRLE, random(320), 10 + random(190))
    { 0.8637s }
    { SprRLE(sampleRLE, random(320), 10 + random(190), 13); }
  end;
  diff := getTimer - startTime;

  print('1000 operations done in ' + f32str(diff) + 's', 0, 0, 15);

  flush;

  { Cleanup }
  FreeRLEBitmap(sampleRLE);
  FreeBMP(image);

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

