
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
  randomize;
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initKeyHandler;
  initMouse;
  initFPSCounter;
end;


procedure update;
var
  a: integer;
begin
  updateDeltaTime;
  incrementFPS;
  updateMouse;

  { TODO: Your update code here }

  if isKeyDown($01) then
    done := true;

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
  cls(1);

  { TODO: Your drawing code here }

  { print('Test VGA mode.', 0, 25, 15); }

  for a:=0 to high(particles) do
    pset(trunc(particles[a].x), trunc(particles[a].y), 15);

  { print('Alive: ' + int2str(countAlive), 0, 16, 15); }

  { circ(50, 40, 10, 15);
  circfill(50, 80, 10, 15);
  rect(50, 40, 120, 70, 15);
  rectfill(50, 80, 120, 110, 15);
  }
  { line(50, 40, 120, 70, 15); }

  trifill(10, 15, 80, 80, 65, 40, 3);
  trifill(50, 50, 100, 20, 150, 75, 2);
  tri(10, 15, 80, 80, 65, 40, 15);
  tri(50, 50, 100, 20, 150, 75, 15);


  drawMouse;

  print('Retro Programming 99', 0, 40, 15);

  { debugMouse; }

  if isKeyDown($11) then
    print('W key is down', 0, 32, 15);
  if isKeyDown($39) then
    print('Spacebar!', 0, 32, 15);

  { Debug delta time }
  {
  print('Delta t: ' + f32str(dt), 0, 0, 7);
  print('GetTimer: ' + f32str(getTimer), 0, 8, 7);
  }


  { Debug heap allocation }
  {
  print('Free heap: ' + i32str(MemAvail) + 'B', 0, 0, 15);
  print('Max mem: ' + i32str(MaxAvail) + 'B', 0, 8, 7);
  }

  { print('delta ms: ' + int2str(deltaMS), 0, 0, 15); }
  { print(int2str(TimerMS), 0, 8, 15); }

  drawFPS;
  flush;
end;


var
  a: integer;

begin
  INIT;
  done := false;

  for a:=0 to high(particles) do
    initParticle(particles[a]);

  repeat
    { limit(60); }

    update;
    draw;
  until done;

  resetMouse;
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.