{
  13-05-2025
  Particles demo
}

uses
  CRT, DOS,
  P92Core, Conv, FPS, Graphics, Logger,
  Keyboard, Mouse,
  Timing, VGA;

type
  TParticle = record
    alive: boolean;
    x, y: single;
    vx, vy: single; { pixels per second }
  end;

var
  particles: array [0..99] of TParticle;
  lastB: boolean;


procedure InitParticle(var p: TParticle);
begin
  p.alive := true;
  p.x := Random(319);
  p.y := Random(199);
  { p.vx := rnd }
  p.vy := Random(100)
end;


function CountAlive: word;
var
  result: word;
  a: integer;
begin
  result := 0;

  for a:=0 to high(particles) do
    if particles[a].alive then
      inc(result);

  CountAlive := result
end;


procedure OnReady; far;
var
  a: word;
begin
  for a:=0 to high(particles) do
    InitParticle(particles[a]);
end;

procedure Update; far;
var
  a: integer;
begin
  if isKeyDown(SC_ESCAPE) then SignalDone;

  for a:=0 to high(particles) do begin
    if particles[a].alive then begin
      particles[a].x := particles[a].x + particles[a].vx * DeltaTime;
      particles[a].y := particles[a].y + particles[a].vy * DeltaTime;

      if particles[a].y >= 200 then
        particles[a].y:=trunc(particles[a].y) mod 200;
    end;
  end;
end;


procedure Draw; far;
var
  a: integer;
begin
  Cls($01);

  for a:=0 to high(particles) do
    Pset(trunc(particles[a].x), trunc(particles[a].y), 15);

  { print('Alive: ' + int2str(CountAlive), 0, 16, 15); }

  { Debug heap allocation }
  {
  print('Free heap: ' + i32str(MemAvail) + 'B', 0, 0, 15);
  print('Max mem: ' + i32str(MaxAvail) + 'B', 0, 8, 7);
  }

  print('Delta t : ' + f32str(DeltaTime), 0, 0, 7);
  print('GetTimer: ' + f32str(GetTimer), 0, 8, 7);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;

  P92Start(appConfig)
end.

