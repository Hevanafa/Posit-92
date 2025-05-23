{
  Animated sprites demo
}

uses
  CRT, DOS,
  Conv, Bitmap, FPS, Logger, Mouse, Timing, VGA;

type
  TExplosion = record
    alive: boolean;
    x, y: integer;
    ttl: double;  { in seconds }
  end;

const
  TARGET_FPS = 35;
  MAX_FRAME_SKIP = 5;
  K_ESC = $01;
var
  done: boolean;
  nextGameTick: double;
  loops: word;
  explosions: array[0..99] of TExplosion;
  imgExplosion: PBitmap;

procedure spr2(
  const image: PBitmap;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer;
  const transparencyKey: byte);
var
  a, b, pos: integer;
begin
  if image = nil then exit;
  
  for b := 0 to srcH - 1 do
  for a := 0 to srcW - 1 do begin
    pos := (srcX + a) + ((srcY + b) * image^.width);
    if image^.data[pos] <> transparencyKey then
      pset(destX + a, destY + b, image^.data[pos]);
  end;
end;

function getFrame(const e: TExplosion): integer;
var
  result: word;
begin
  result := trunc((0.5 - e.ttl) / 0.125);
  if result = 4 then
    getFrame := 3
  else
    getFrame := result
end;

procedure initExplosion(var e: TExplosion);
begin
  e.alive := true;
  e.x := random(300);
  e.y := random(180);
  e.ttl := 0.5
end;

procedure INIT;
var
  a: word;
begin
  randomize;
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initMouse;
  initFPSCounter;

  loadBMP(imgExplosion, 'IMG\SPRITESH.BMP');
  
  for a:=0 to high(explosions) do begin
    initExplosion(explosions[a]);
    explosions[a].ttl := random * 0.5;
  end;
end;


procedure update;
var
  a: integer;
begin
  updateDeltaTime;
  updateMouse;
  incrementFPS;

  for a:=0 to high(explosions) do
    if explosions[a].alive then begin
      explosions[a].ttl := explosions[a].ttl - dt;
      if explosions[a].ttl <= 0 then
        explosions[a].alive := false;
    end else
      initExplosion(explosions[a]);

  if keyPressed then
    if readKey = #27 then done := true;
end;


procedure draw;
var
  a: integer;
begin
  cls($7D);

  for a:=0 to high(explosions) do begin
    { spr(imgExplosion, explosions[a].x, explosions[a].y, 13); }

    spr2(
      imgExplosion,
      getFrame(explosions[a]) * 16, 0, 16, 16,
      explosions[a].x, explosions[a].y, 13);
      
      { print(i32str(getFrame(explosions[a])), explosions[a].x, explosions[a].y, 15); }
  end;
  
  drawMouse;
  drawFPS;
  flush
end;


begin
  INIT;
  done := false;

  { without frameskipping: 27-29 FPS }
  {
  repeat
    update;
    draw
  until done;
  }

  { with frameskipping: 35-39 FPS }
  nextGameTick := getTimer;
  repeat
    loops := 0;
    
    while (getTimer > nextGameTick) and (loops < MAX_FRAME_SKIP) do begin
      update;
      nextGameTick := nextGameTick + (1 / TARGET_FPS);
      inc(loops)
    end;
    draw;
  until done;

  freeBMP(imgExplosion);

  resetMouse;
  freeBuffer;
  closeLogger;
  initTextMode
end.
