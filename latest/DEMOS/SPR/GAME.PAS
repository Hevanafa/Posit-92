{
  100 spr demo
}

uses
  CRT, DOS,
  P92Core, Bitmap, Logger, Keyboard, FPS, Timing, VGA;

type
  TVec2 = record
    x, y: double;
  end;

var
  { Asset variables }
  imgGrass: PBitmap;
  { Game state variables }
  positions: array[0..99] of TVec2;


procedure OnPreload; far;
begin
  LoadBMP(imgGrass, 'IMG\GRASS.BMP');
end;

procedure OnReady; far;
var
  a: integer;
begin
  for a:=0 to high(positions) do
    with positions[a] do begin
      x := trunc(random(300));
      y := trunc(random(180))
    end;
end;


procedure OnCleanup; far;
begin
  freeBMP(imgGrass)
end;

procedure Update; far;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;
end;


procedure Draw; far;
var
  a: integer;
begin
  cls($7D);
  
  for a:=0 to high(positions) do
    spr(imgGrass, trunc(positions[a].x), trunc(positions[a].y), 13);
end;

var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.LoadDefaultCursor := false;
  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

