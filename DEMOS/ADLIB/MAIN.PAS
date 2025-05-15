
uses
  CRT, DOS,
  Logger, Keyboard, Timing, VGA,
  Bitmap, Conv, FPS, Adlib;

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

const
  K_ESC = $01;
var
  done: boolean;
  t: double;
  DosuEXE: array[0..1] of PBitmap;
  score: integer;
  playerX, playerY: single;
  playerHitbox: TRect;
  lastB: boolean;
  imgCoin: PBitmap;
  coins: array[0..9] of TCoin;
  rotation: double;


procedure initCoin(var c: TCoin);
begin
  c.hitbox.x := random(300);
  c.hitbox.y := random(180);
  c.hitbox.width := 24;
  c.hitbox.height := 16
end;

procedure randomiseCoins;
var
  a: word;
begin
  for a:=0 to high(coins) do
    initCoin(coins[a]);
end;

procedure INIT;
begin
  randomize;
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initKeyHandler;
  { initMouse; }
  initFPSCounter;

  { PCSpeaker.init; }
  AdlibDrv.init;

  loadBMP(dosuEXE[0], 'IMG\DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG\DOSU_2.BMP');
  loadBMP(imgCoin, 'IMG\COIN.BMP');

  playerX := 148;
  playerY := 76;
  with playerHitbox do begin
    x := trunc(playerX);
    y := trunc(playerY);
    width := 24;
    height := 24;
  end;

  rotation := 45;

  randomiseCoins;
end;

procedure updateCoins;
var
  a: word;
begin
  for a:=0 to high(coins) do
    if coins[a].hitbox.intersects(playerHitbox) then begin
      inc(score, 1);
      initCoin(coins[a]);
      { PCSpeaker.playMelody(SoundIDs(random(3))); }
      AdlibDrv.startMelody
    end;
end;

procedure drawCoins;
var
  a: word;
begin
  for a:=0 to high(coins) do
    if (a and 1) = 0 then
      spr(imgCoin, coins[a].hitbox.x, coins[a].hitbox.y, 13)
    else
      sprTint(imgCoin, coins[a].hitbox.x, coins[a].hitbox.y, 13, 15);
end;

procedure update;
var
  a: integer;
begin
  updateDeltaTime;
  { updateMouse; }
  incrementFPS;

  { TODO: Your update code here }
  { PCSpeaker.updateMelody; }
  AdlibDrv.update;

  if isKeyDown(K_ESC) then done := true;

  {
  if lastB <> isKeydown($30) then begin
    lastB := isKeydown($30);
    if lastB then
      PCSpeaker.playMelody(Melody1);
  end;
  }


  if lastB <> isKeydown($30) then begin
    lastB := isKeydown($30);
    if lastB then
      AdlibDrv.startMelody;
  end;

  if isKeyDown($11) then playerY := playerY - dt * 60;
  if isKeyDown($1F) then playerY := playerY + dt * 60;

  if isKeyDown($1E) then playerX := playerX - dt * 60;
  if isKeyDown($20) then playerX := playerX + dt * 60;

  { Check bounds }
  if playerX < 0 then playerX := 0;
  if playerX > 320 - 24 then playerX := 320 - 24;
  if playerY < 0 then playerY := 0;
  if playerY > 200 - 24 then playerY := 200 - 24;

  playerHitbox.x := trunc(playerX);
  playerHitbox.y := trunc(playerY);

  t:=t+dt;

  updateCoins;
end;


procedure draw;
var
  a: integer;
  scoreStr: string;
begin
  cls($7D);

  { TODO: Your drawing code here }

  print('WASD - Move', 160-48, 120, 15);
  { print('B - beep', 160-32, 130, 15); }

  if (trunc(t * 1.5) and 1) = 0 then
    spr(dosuEXE[0], trunc(playerX), trunc(playerY), 13)
  else
    spr(dosuEXE[1], trunc(playerX), trunc(playerY), 13);

  drawCoins;

  { Optional rotated sprite }
  { sprPro(dosuEXE[0], 48, 48, rotation, 13); }

  { Rotated sprites test }
  { for a:=0 to 3 do
    sprPro2(dosuEXE[0], 144 + a * 40, 48, 1.5, 1, rotation + 90, 13); }

  { for a:=0 to 3 do
    sprProLUT(dosuEXE[0], 144 + a * 40, 48, 1.5, 1, trunc(rotation) mod 360 div 10, 13); }

  { Debug rotation }
  { print('Rotation:' + f32str(rotation), 0, 0, 15); }

  { print('x:' + f32str(playerX) + ', y:' + f32str(playerY), 0, 0, 7); }
  scoreStr := i32str(score);
  print(scoreStr, (320 - length(scoreStr) * 8) div 2, 8, 15);

  { drawMouse; }
  drawFPS;
  flush
end;


var
  a: integer;

begin
  INIT;
  done := false;

  repeat
    update;
    draw;
  until done;

  { resetMouse; }
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
