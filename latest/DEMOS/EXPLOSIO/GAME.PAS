{
  Animated sprites demo
}

uses
  CRT, DOS,
  P92Core, P92CONV, P92TEX, FPS, P92LOG, P92TIME, P92VGA;

type
  TExplosion = record
    alive: boolean;
    x, y: integer;
    ttl: double;  { in seconds }
  end;

var
  { Asset variables }
  imgExplosion: TTexture;

  { Game state variables }
  nextGameTick: double;
  loops: word;
  explosions: array[0..99] of TExplosion;


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

procedure InitExplosion(var e: TExplosion);
begin
  e.alive := true;
  e.x := random(300);
  e.y := random(180);
  e.ttl := 0.5
end;


procedure OnPreload; far;
begin
  LoadTex(imgExplosion, 'IMG\SPRITESH.BMP');
end;

procedure OnCleanup; far;
begin
  FreeTex(imgExplosion);
end;

procedure OnReady; far;
var
  a: word;
begin
  for a:=0 to high(explosions) do begin
    InitExplosion(explosions[a]);
    explosions[a].ttl := random * 0.5;
  end;
end;


procedure Update; far;
var
  a: integer;
begin
  if KeyPressed and (ReadKey = #27) then SignalDone;

  for a:=0 to high(explosions) do
    if explosions[a].alive then begin
      explosions[a].ttl := explosions[a].ttl - DeltaTime;
      if explosions[a].ttl <= 0 then
        explosions[a].alive := false;
    end else
      InitExplosion(explosions[a]);
end;


procedure Draw; far;
var
  a: integer;
begin
  cls($7D);

  for a:=0 to high(explosions) do
    SprRegion(
      imgExplosion,
      GetFrame(explosions[a]) * 16, 0, 16, 16,
      explosions[a].x, explosions[a].y);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.EnableKeyHandler := false;
  appConfig.WaitMode := P92WaitVSync;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

