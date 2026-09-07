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
      spr(texCoin, coins[a].zone.x, coins[a].zone.y)
    else
      sprTint(texCoin, coins[a].zone.x, coins[a].zone.y, 15);
end;

procedure Update; far;
var
  a: integer;
begin
  if isKeyDown(SC_ESCAPE) then SignalDone;

  if isKeyDown($11) then playerY := playerY - DeltaTime * 60;
  if isKeyDown($1F) then playerY := playerY + DeltaTime * 60;

  if isKeyDown($1E) then playerX := playerX - DeltaTime * 60;
  if isKeyDown($20) then playerX := playerX + DeltaTime * 60;

  { Check bounds }
  if playerX < 0 then playerX := 0;
  if playerX > 320 - 24 then playerX := 320 - 24;
  if playerY < 0 then playerY := 0;
  if playerY > 200 - 24 then playerY := 200 - 24;

  playerZone.x := trunc(playerX);
  playerZone.y := trunc(playerY);

  UpdateCoins;

  t:=t+DeltaTime;
end;


procedure Draw; far;
var
  a: integer;
  scoreStr: string;
begin
  cls($7D);

  { TODO: Your drawing code here }

  print('WASD - Move', 160-48, 120, 15);
  { print('B - beep', 160-32, 130, 15); }

  if (trunc(t * 1.5) and 1) = 0 then
    spr(texDosuEXE[0], trunc(playerX), trunc(playerY))
  else
    spr(texDosuEXE[1], trunc(playerX), trunc(playerY));

  DrawCoins;

  { Optional rotated sprite }
  { sprPro(texDosuEXE[0], 48, 48, rotation, 13); }

  { Rotated sprites test }
  { for a:=0 to 3 do
    sprPro2(texDosuEXE[0], 144 + a * 40, 48, 1.5, 1, rotation + 90, 13); }

  { for a:=0 to 3 do
    sprProLUT(texDosuEXE[0], 144 + a * 40, 48, 1.5, 1, trunc(rotation) mod 360 div 10, 13); }

  { Debug rotation }
  { print('Rotation:' + f32str(rotation), 0, 0, 15); }

  { print('x:' + f32str(playerX) + ', y:' + f32str(playerY), 0, 0, 7); }
  scoreStr := i32str(score);
  print(scoreStr, (320 - length(scoreStr) * 8) div 2, 8, 15);
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

