{ TODO: Separate delta time & FPS each to their own units }

uses
  crt, dos,
  conv, fps, timing, vga;

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
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initFPSCounter;
end;


procedure update;
var
  a: integer;
begin
  if keyPressed then begin
    if readKey = #27 then
      done := true;
  end;

  { dt := deltaMS / 1000; }

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
  { print('Test VGA mode.', 0, 25, 15); }

  for a:=0 to high(particles) do
    pset(trunc(particles[a].x), trunc(particles[a].y), 15);

  { print('Alive: ' + int2str(countAlive), 0, 16, 15); }

  { for a:=0 to 9 do }
  { print(int2str(a) + ': [' +
  int2str(trunc(particles[a].x)) + ',' + int2str(trunc(particles[a].y)) + ']', 0, 24 + a * 8, 15); }

  { print(f32str(rnd), 0, 0, 15); }
  print('Delta t: ' + f32str(dt), 0, 0, 15);
  print(f32str(getTimer), 0, 8, 15);
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

    updateDeltaTime;
    incrementFPS;

    update;
    draw;
  until done;

  freeBuffer;
  initTextMode
end.