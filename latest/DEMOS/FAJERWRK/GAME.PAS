{$DEFINE DEBUG}

uses
  CRT, DOS,
  P92Core, Bitmap, Conv, FPS, Graphics, Logger,
  Keyboard, Mouse, Timing, VGA;

type
  TPoint = record
    x, y: byte;
  end;
  TParticle = record
    alive: boolean;
    colour: byte;
    deathTick: double;
    x, y: double;
    lastX, lastY: array[0..3] of double;
    vx, vy: double;
  end;

var
  t: double;
  nextParticleTick: double;
  stars: array[0..29] of TPoint;
  particles: array[0..399] of TParticle;


procedure OnReady; far;
var
  a: integer;
begin
  t := 0.0;

  nextParticleTick := getTimer + 0.5;
  for a:=0 to high(stars) do begin
    stars[a].x := 20 + random(280);
    stars[a].y := 20 + random(160);
  end;
end;

procedure Explode(const cx, cy: double);
var
  a, i, count: word;
  colour: byte;
  now, angle: double;
begin
  now := getTimer;
  
  count := 0;
  colour := 9 + random(7);
  for a:=0 to high(particles) do begin
    if particles[a].alive then continue;
    
    particles[a].alive := true;
    particles[a].colour := colour;
    particles[a].deathTick := getTimer + 2.0;
    particles[a].x := cx;
    particles[a].y := cy;
    for i:=0 to high(particles[a].lastX) do begin
      particles[a].lastX[i] := cx;
      particles[a].lastY[i] := cy;
    end;
    {
    particles[a].vx := 4 * (random - 0.5);
    particles[a].vy := 4 * (random - 0.5);
    }
    angle := random * 2 * pi;
    particles[a].vx := (2 - random / 2) * sin(angle);
    particles[a].vy := (2 - random / 2) * cos(angle);
    
    {
    if random < 0.5 then
      particles[a].vx := -1 - random
    else
      particles[a].vx := 1 + random;
    
    if random < 0.5 then
      particles[a].vy := -1 - random
    else
      particles[a].vy := 1 + random;
    }
    
    inc(count);
    if count >= 100 then break;
  end;
end;

procedure Update; far;
var
  a, i: word;
  now: double;
begin
  now := getTimer;
  for a:=0 to high(particles) do begin
    if not particles[a].alive then continue;
    
    for i:=1 to high(particles[a].lastX) do begin
      particles[a].lastX[i] := particles[a].lastX[i-1];
      particles[a].lastY[i] := particles[a].lastY[i-1];
    end;
    particles[a].lastX[0] := particles[a].x;
    particles[a].lastY[0] := particles[a].y;
    particles[a].x := particles[a].x + particles[a].vx;
    particles[a].y := particles[a].y + particles[a].vy;
    
    particles[a].vx := particles[a].vx * 0.98;
    particles[a].vy := particles[a].vy * 0.98;
    { gravitational acceleration }
    particles[a].vy := particles[a].vy + 0.02;
    
    if (particles[a].x < 0) or (particles[a].x >= 320) then
      particles[a].alive := false;
    if (particles[a].y >= 200) then
      particles[a].alive := false;
    if now >= particles[a].deathTick then
      particles[a].alive := false;
  end;
  
  if now >= nextParticleTick then begin
    nextParticleTick := now + 0.5;
    Explode(20 + random(280), 20 + random(160));
  end;
  
  { TODO: Implement mouse input to Explode more particles }

  if isKeyDown(SC_ESCAPE) then SignalDone;
  
  t:=t+DeltaTime;
end;


procedure Draw; far;
var
  a, i: word;
  aliveCount: word;
begin
  asmCls($00);
  
  for a:=0 to high(stars) do begin
    if (a and 1) = 1 then
      asmPset(stars[a].x, stars[a].y, 15)
    else
      asmPset(stars[a].x, stars[a].y, 7);
  end;

  aliveCount := 0;
  for a:=0 to high(particles) do begin
    if not particles[a].alive then continue;
    
    inc(aliveCount);
    
    for i:=0 to high(particles[a].lastX) - 1 do
      line(
        trunc(particles[a].lastX[i]),
        trunc(particles[a].lastY[i]),
        trunc(particles[a].lastX[i+1]),
        trunc(particles[a].lastY[i+1]),
        particles[a].colour);
    
    line(
      trunc(particles[a].lastX[0]), trunc(particles[a].lastY[0]),
      trunc(particles[a].x), trunc(particles[a].y),
      particles[a].colour);
      
    { asmPset(
      trunc(particles[a].x), trunc(particles[a].y),
      15); }
  end;
  
  {
  asmPrint('nextParticleTick: ' + f32str(nextParticleTick), 0, 0, 7);
  asmPrint('Alive: ' + i32str(aliveCount), 0, 8, 7);
  }
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.LoadDefaultCursor := false;

  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;

  P92Start(appConfig)
end.

