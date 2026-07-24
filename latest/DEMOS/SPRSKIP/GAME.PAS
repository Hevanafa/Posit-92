{
  Animated sprites demo
}

uses
  CRT, DOS,
  P92Core, Conv, Bitmap,
  Keyboard, Mouse,
  Timing, VGA;

type
  TExplosion = record
    alive: boolean;
    x, y: integer;
    ttl: double;  { in seconds }
  end;

const
  maxSpritesPerFrame = 50;
var
  { Asset variables }
  imgExplosion: PBitmap;

  { Game state variables }
  startTime, nextGameTick: double;
  flipInt: word;
  loops: word;
  explosions: array[0..99] of TExplosion;
  frameCounter: integer;


function GetFrame(const e: TExplosion): integer;
var
  result: word;
begin
  result := trunc((0.5 - e.ttl) / 0.125);
  if result = 4 then
    GetFrame := 3
  else
    GetFrame := result
end;

procedure DrawSprite(const e: TExplosion);
begin
  SprRegion(
    imgExplosion,
    GetFrame(e) * 16, 0, 16, 16,
    e.x, e.y, 13);
end;

procedure InitExplosion(var e: TExplosion);
begin
  e.alive := true;
  e.x := random(300);
  e.y := random(180);
  e.ttl := 0.5
end;


procedure OnPreload; far;
begin
  loadBMP(imgExplosion, 'IMG\SPRITESH.BMP');
end;

procedure OnCleanup; far;
begin
  freeBMP(imgExplosion);
end;

procedure OnReady; far;
var
  a: word;
begin
  for a:=0 to high(explosions) do begin
    InitExplosion(explosions[a]);
    explosions[a].ttl := random * 0.5;
  end;

  startTime := getTimer;
  flipInt := 0;
  frameCounter := 0;
end;


procedure Update; far;
var
  a: integer;
begin
  for a:=0 to high(explosions) do
    if explosions[a].alive then begin
      explosions[a].ttl := explosions[a].ttl - DeltaTime;
      if explosions[a].ttl <= 0 then
        explosions[a].alive := false;
    end else
      InitExplosion(explosions[a]);

  if IsKeyDown(SC_ESCAPE) then SignalDone;
end;


procedure Draw; far;
var
  a, startIdx, totalSprites: integer;

begin
  cls($7D);

  { Half list flickering }
  inc(frameCounter);
  if frameCounter > 256 then
    frameCounter := frameCounter shr 8;

  for a := 0 to high(explosions) do
    if (frameCounter and 1) = (a and 1) then
      DrawSprite(explosions[a]);


  { Round-Robin flickering }
  {
  inc(frameCounter);
  if frameCounter > 256 then
    frameCounter := frameCounter shr 8;

  totalSprites := (high(explosions) + 1);
  startIdx := (frameCounter * maxSpritesPerFrame) mod totalSprites;

  for a := 0 to maxSpritesPerFrame - 1 do begin
    DrawSprite(explosions[(startIdx + a) mod totalSprites]);
  end;
  }

  print(i32str(frameCounter), 0, 0, 15);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

