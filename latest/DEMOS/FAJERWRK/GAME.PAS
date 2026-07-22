{$DEFINE DEBUG}

uses
  CRT, DOS,
  Bitmap, Conv, FPS, Graphics, Logger,
  Keyboard, Mouse, Timing, VGA;

const
  SC_ESC = $01;
  
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
  done: boolean;
  t: double;
  nextParticleTick: double;
  stars: array[0..29] of TPoint;
  particles: array[0..399] of TParticle;


procedure INIT;
var
  a: word;
begin
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initKeyHandler;
  initMouse;
  
  initFPSCounter;
  
  randomize;

  for a:=0 to high(stars) do begin
    stars[a].x := 20 + random(280);
    stars[a].y := 20 + random(160);
  end;
end;


procedure explode(const cx, cy: double);
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

procedure update;
var
  a, i: word;
  now: double;
begin
  updateDeltaTime;
  updateMouse;
  
  incrementFPS;
  
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
    explode(20 + random(280), 20 + random(160));
  end;
  
  { TODO: Implement mouse input }

  if isKeyDown(SC_ESC) then done := true;
  
  t:=t+dt
end;


procedure draw;
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
  
  drawMouse;
  drawFPS;
  asmFlush
end;


begin
  INIT;
  done := false;
  nextParticleTick := getTimer + 0.5;

  repeat
    update;
    draw;
    { limit(70); }
  until done;

  resetMouse;
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
