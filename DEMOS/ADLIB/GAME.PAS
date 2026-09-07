{
  AdLib demo project
  Part of Posit-92 game engine

  Requires P92_ADLIB custom directive enabled
}

uses
  CRT, DOS,
  P92CORE, P92GEOM, P92TEX, P92CONV, P92LOG, P92KBD, P92MOUSE, P92TIME, P92VGA,
  P92ADLIB;

type
  TCoin = record
    zone: TZone
  end;


const
  Velocity = 60;  { pixels per second }

var
  { Asset variables }
  texDosuEXE: array[0..1] of TTexture;
  texCoin: TTexture;
  BrightFMInstrument: TInstrument;
  sfxCoin: TMelody;

  { Game state variables }
  t: double;
  score: integer;
  playerZone: TZone;
  coins: array[0..9] of TCoin;


procedure InitInstruments;
begin
  with BrightFMInstrument do begin
    with carrier do begin
      tremolo := false;
      vibrato := false;
      sustain := true;
      keyScale := false;
      multiplier := 1;
      totalLevel := 0;
      attackRate := 15;
      decayRate := 4;
      sustainRate := 2;
      releaseRate := 7;
      waveform := 0;
    end;

    with modulator do begin
      tremolo := false;
      vibrato := true;
      sustain := true;
      keyScale := false;
      multiplier := 1;
      totalLevel := 26;
      attackRate := 15;
      decayRate := 4;
      sustainRate := 3;
      releaseRate := 6;
      waveform := 0;
    end;

    feedback := 5;
    algorithm := 0
  end;
end;


procedure InitCoin(var c: TCoin);
begin
  c.zone.x := random(300);
  c.zone.y := random(180);
  c.zone.width := 24;
  c.zone.height := 16
end;

procedure RandomiseCoins;
var
  a: word;
begin
  for a:=0 to high(coins) do
    InitCoin(coins[a]);
end;

procedure OnPreload; far;
begin
  LoadTex(texDosuEXE[0], 'IMG\DOSU_1.BMP');
  LoadTex(texDosuEXE[1], 'IMG\DOSU_2.BMP');
  LoadTex(texCoin, 'IMG\COIN.BMP');

  InitInstruments;

  InitMelody(sfxCoin, BrightFMInstrument, 3);

  InitNote(sfxCoin.notes^[0], NOTE_C, 5, 0.05, 127);
  InitNote(sfxCoin.notes^[1], NOTE_E, 5, 0.05, 127);
  InitNote(sfxCoin.notes^[2], NOTE_F, 5, 0.05, 127)
end;

procedure OnCleanup; far;
begin
  FreeTex(texDosuEXE[0]);
  FreeTex(texDosuEXE[1]);
  FreeTex(texCoin);

  FreeMelody(sfxCoin);
end;

procedure OnReady; far;
begin
  with playerZone do begin
    x := 148;
    y := 76;
    width := 24;
    height := 24;
  end;

  RandomiseCoins
end;

procedure UpdateCoins;
var
  a: word;
begin
  for a:=0 to high(coins) do
    if ZoneIntersects(playerZone, coins[a].zone) then begin
      inc(score, 1);
      InitCoin(coins[a]);
      P92ADLIB.PlayMelody(sfxCoin, 0);
    end;
end;

procedure DrawCoins;
var
  a: word;
begin
  for a:=0 to high(coins) do
    if (a and 1) = 0 then
      Spr(texCoin, trunc(coins[a].zone.x), trunc(coins[a].zone.y))
    else
      SprTint(texCoin, trunc(coins[a].zone.x), trunc(coins[a].zone.y), $0F);
end;

procedure Update; far;
var
  a: integer;
begin
  if isKeyDown(SC_ESCAPE) then SignalDone;

  if isKeyDown(SC_W) then
    playerZone.y := playerZone.y - Velocity * DeltaTime;

  if isKeyDown(SC_S) then
    playerZone.y := playerZone.y + Velocity * DeltaTime;

  if isKeyDown(SC_A) then
    playerZone.x := playerZone.x - Velocity * DeltaTime;

  if isKeyDown(SC_D) then
    playerZone.x := playerZone.x + Velocity * DeltaTime;

  { Check bounds }
  if playerZone.x < 0 then
    playerZone.x := 0;
  if playerZone.x > VGAWidth - 24 then
    playerZone.x := VGAWidth - 24;

  if playerZone.y < 0 then
    playerZone.y := 0;
  if playerZone.y > VGAHeight - 24 then
    playerZone.y := VGAHeight - 24;

  UpdateCoins;

  t:=t+DeltaTime;
end;


procedure Draw; far;
var
  scoreStr: string;
begin
  cls($7D);

  print('WASD - Move', 160-48, 120, 15);

  if (trunc(t * 1.5) and 1) = 0 then
    spr(texDosuEXE[0], trunc(playerZone.x), trunc(playerZone.y))
  else
    spr(texDosuEXE[1], trunc(playerZone.x), trunc(playerZone.y));

  DrawCoins;

  scoreStr := i32str(score);
  print(scoreStr, (320 - length(scoreStr) * 8) div 2, 8, 15);
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

