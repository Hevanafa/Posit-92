{
  AdLib demo project
  Part of Posit-92 game engine

  Requires P92_ADLIB custom directive enabled
}

uses
  CRT, DOS,
  P92Core, P92TEX, P92CONV, P92LOG, P92KBD, P92MOUSE, P92TIME, P92VGA,
  P92ADLIB;

type
  TRect = object
    x, y, width, height: integer;
    function intersects(other: TRect): boolean;
  end;
  TCoin = record
    hitbox: TRect
  end;

function TRect.intersects(other: TRect): boolean;
begin
  intersects :=
    (other.x < self.x + self.width) and
    (self.x < other.x + other.width) and
    (other.y < self.y + self.height) and
    (self.y < other.y + other.height)
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
  playerX, playerY: single;
  playerHitbox: TRect;
  lastB: boolean;
  coins: array[0..9] of TCoin;
  rotation: double;


procedure InitInstruments;
begin
  with BrightFMInstrument do begin
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
    
    feedback := 5;
    algorithm := 0
  end;
end;


procedure InitCoin(var c: TCoin);
begin
  c.hitbox.x := random(300);
  c.hitbox.y := random(180);
  c.hitbox.width := 24;
  c.hitbox.height := 16
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
  { AdlibDrv.AssignInstrument(0, @BrightFMInstrument); }

  with sfxCoin do begin
    noteCount := 3;
    instrument := @BrightFMInstrument;
    InitNote(notes[0], NOTE_C, 5, 0.05, 127);
    InitNote(notes[1], NOTE_E, 5, 0.05, 127);
    InitNote(notes[2], NOTE_F, 5, 0.05, 127)
  end;
end;

procedure OnCleanup; far;
begin
  FreeTex(texDosuEXE[0]);
  FreeTex(texDosuEXE[1]);
  FreeTex(texCoin);
end;

procedure OnReady; far;
begin
  playerX := 148;
  playerY := 76;

  with playerHitbox do begin
    x := trunc(playerX);
    y := trunc(playerY);
    width := 24;
    height := 24;
  end;

  rotation := 45;

  RandomiseCoins;
end;

procedure UpdateCoins;
var
  a: word;
begin
  for a:=0 to high(coins) do
    if coins[a].hitbox.intersects(playerHitbox) then begin
      inc(score, 1);
      InitCoin(coins[a]);
      { PCSpeaker.playMelody(SoundIDs(random(3))); }
      P92ADLIB.PlayMelody(@sfxCoin, 0);
    end;
end;

procedure DrawCoins;
var
  a: word;
begin
  for a:=0 to high(coins) do
    if (a and 1) = 0 then
      spr(texCoin, coins[a].hitbox.x, coins[a].hitbox.y)
    else
      sprTint(texCoin, coins[a].hitbox.x, coins[a].hitbox.y, 15);
end;

procedure Update; far;
var
  a: integer;
begin
  if isKeyDown(SC_ESCAPE) then SignalDone;

  {
  if lastB <> isKeydown($30) then begin
    lastB := isKeydown($30);
    if lastB then
      PCSpeaker.playMelody(Melody1);
  end;
  }


  if lastB <> isKeydown($30) then begin
    lastB := isKeydown($30);
    {
    if lastB then
      AdlibDrv.startMelody;
    }
  end;

  if isKeyDown($11) then playerY := playerY - DeltaTime * 60;
  if isKeyDown($1F) then playerY := playerY + DeltaTime * 60;

  if isKeyDown($1E) then playerX := playerX - DeltaTime * 60;
  if isKeyDown($20) then playerX := playerX + DeltaTime * 60;

  { Check bounds }
  if playerX < 0 then playerX := 0;
  if playerX > 320 - 24 then playerX := 320 - 24;
  if playerY < 0 then playerY := 0;
  if playerY > 200 - 24 then playerY := 200 - 24;

  playerHitbox.x := trunc(playerX);
  playerHitbox.y := trunc(playerY);

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

