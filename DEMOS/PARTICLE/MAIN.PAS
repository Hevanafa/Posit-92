
{
  13-05-2025
  Particles demo
}

uses
  CRT, DOS,
  Conv, FPS, Logger, Keyboard, Mouse, Timing, VGA,
  Graphics;

type
  TParticle = record
    alive: boolean;
    x, y: single;
    vx, vy: single; { pixels per second }
  end;

var
  done: boolean;
  particles: array [0..99] of TParticle;
  lastB: boolean;


procedure initParticle(var p: TParticle);
begin
  p.alive := true;
  p.x := Random(319);
  p.y := Random(199);
  { p.vx := rnd }
  p.vy := Random(100)
end;


function countAlive: word;
var
  result: word;
  a: integer;
begin
  result := 0;
  for a:=0 to high(particles) do
    if particles[a].alive then
      result:=result + 1;

  countAlive:=result;
end;


procedure INIT;
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
end;


procedure update;
var
  a: integer;
begin
  updateDeltaTime;
  incrementFPS;
  updateMouse;

  if isKeyDown($01) then done := true;

  for a:=0 to high(particles) do begin
    if particles[a].alive then begin
      particles[a].x:=particles[a].x + particles[a].vx * dt;
      particles[a].y:=particles[a].y + particles[a].vy * dt;

      if particles[a].y >= 200 then
        particles[a].y:=trunc(particles[a].y) mod 200;
    end;
  end;
end;


procedure draw;
var
  a: integer;
begin
  asmCls($01);

  for a:=0 to high(particles) do
    pset(trunc(particles[a].x), trunc(particles[a].y), 15);

  { print('Alive: ' + int2str(countAlive), 0, 16, 15); }

  drawMouse;

  if isKeyDown($11) then
    print('W key is down', 0, 32, 15);
  if isKeyDown($39) then
    print('Spacebar!', 0, 32, 15);


  { Debug heap allocation }
  {
  print('Free heap: ' + i32str(MemAvail) + 'B', 0, 0, 15);
  print('Max mem: ' + i32str(MaxAvail) + 'B', 0, 8, 7);
  }

  print('Delta t : ' + f32str(dt), 0, 0, 7);
  print('GetTimer: ' + f32str(getTimer), 0, 8, 7);

  drawFPS;
  asmFlush
end;


var
  a: integer;

begin
  INIT;
  done := false;

  for a:=0 to high(particles) do
    initParticle(particles[a]);

  repeat
    update;
    draw;
    { limit(60) }
  until done;

  resetMouse;
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
