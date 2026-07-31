{ Game implementation with PCSpeaker }

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92Core, Logger, P92KBD, Timing, P92VGA,
  Bitmap, Conv, PCSPKR;

type
  TRect = object
    x, y, width, height: integer;
    function Intersects(other: TRect): boolean;
  end;
  TCoin = record
    hitbox: TRect
  end;

function TRect.Intersects(other: TRect): boolean;
begin
  Intersects :=
    (other.x < self.x + self.width) and
    (self.x < other.x + other.width) and
    (other.y < self.y + self.height) and
    (self.y < other.y + other.height)
end;


var
  { Asset variables }
  imgDosuEXE: array[0..1] of TBitmap;
  imgCoin: TBitmap;
  coinMelodyList: array[0..2] of TMelody;

  { Game state variables }
  t: double;
  score: integer;
  playerX, playerY: single;
  playerHitbox: TRect;
  lastB: boolean;
  coins: array[0..9] of TCoin;
  rotation: double;


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
  LoadBMP(imgDosuEXE[0], 'IMG\DOSU_1.BMP');
  LoadBMP(imgDosuEXE[1], 'IMG\DOSU_2.BMP');
  LoadBMP(imgCoin, 'IMG\COIN.BMP');

  { C4 E4 G4 }
  CreateMelody(coinMelodyList[0], 3);
  with coinMelodyList[0] do begin
    InitNote(notes^[0], 261, 0.1);
    InitNote(notes^[1], 329, 0.1);
    InitNote(notes^[2], 392, 0.1);
  end;

  { D4 F#4 A4 }
  CreateMelody(coinMelodyList[1], 3);
  with coinMelodyList[1] do begin
    InitNote(notes^[0], 293, 0.1);
    InitNote(notes^[1], 370, 0.1);
    InitNote(notes^[2], 440, 0.1);
  end;

  CreateMelody(coinMelodyList[2], 3);
  with coinMelodyList[2] do begin
    InitNote(notes^[0], 329, 0.1);
    InitNote(notes^[1], 415, 0.1);
    InitNote(notes^[2], 494, 0.1);
  end;
end;

procedure OnCleanup; far;
var
  a: word;
begin
  for a:=0 to high(coinMelodyList) do
    FreeMelody(coinMelodyList[a]);

  FreeBMP(imgDosuEXE[0]);
  FreeBMP(imgDosuEXE[1]);
  FreeBMP(imgCoin);
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
    if coins[a].hitbox.Intersects(playerHitbox) then begin
      inc(score, 1);
      InitCoin(coins[a]);
      PlayMelody(@coinMelodyList[random(3)]);
    end;
end;

procedure DrawCoins;
var
  a: word;
begin
  for a:=0 to high(coins) do
    if (a and 1) = 0 then
      Spr(imgCoin, coins[a].hitbox.x, coins[a].hitbox.y)
    else
      SprTint(imgCoin, coins[a].hitbox.x, coins[a].hitbox.y, 15);
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

  if isKeyDown($11) then playerY := playerY - DeltaTime * 60;
  if isKeyDown($1F) then playerY := playerY + DeltaTime * 60;

  if isKeyDown($1E) then playerX := playerX - DeltaTime * 60;
  if isKeyDown($20) then playerX := playerX + DeltaTime * 60;

  {
  if isKeyDown($4B) then rotation := rotation - dt * 60;
  if isKeyDown($4D) then rotation := rotation + dt * 60;
  }
  rotation := rotation + DeltaTime * 60;
  if rotation > 360 then rotation := rotation - 360;

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

  print('WASD - Move', 160-48, 120, 15);

  if (trunc(t * 1.5) and 1) = 0 then
    spr(imgDosuEXE[0], trunc(playerX), trunc(playerY))
  else
    spr(imgDosuEXE[1], trunc(playerX), trunc(playerY));

  DrawCoins;

  { print('x:' + f32str(playerX) + ', y:' + f32str(playerY), 0, 0, 7); }
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

