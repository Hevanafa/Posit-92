
uses
  crt, dos,
  vga;

type
  TParticle = record
    alive: boolean;
    x, y: single;
    vx, vy: single; { pixels per second }
  end;


var
  done: boolean;
  fps, lastFPS: integer;
  lastFPSTime: double; { in seconds }
  dt, newTime, lastTime: double; { in seconds }
  { deltaMS, lastMS: longint; }

  particles: array [0..99] of TParticle;

function i32str(value: longInt): string;
var
  result: string;
begin
  str(value, result);
  i32str := result
end;

function f32str(value: double): string;
var
  result: string;
begin
  str(value:0:4, result);
  f32str := result
end;


function Timer: real;
begin
  Timer := MemL[$0040:$006C] / 18.2065
end;

{ Higher resolution TIMER with microsecond precision, shortened }
function GetTimer: real;
var
  counter: word;
begin
  { Read current PIT countdown }
  Port[$43] := $00;  { Set up channel 0 latch command }
  counter := Port[$40];
  counter := counter or (Port[$40] shl 8);  { Read low & high bytes }
  { MemL accesses BIOS tick count }
  GetTimer := (MemL[$0040:$006C] + (65536 - counter) / 65536) / 18.2065;
end;


function TimerMS: Longint;
var
  ticks: Longint;
  count: word;
begin
  ticks := MemL[$0040:$006C];
  Port[$43] := $00;
  { count := Port[$40] or (Port[$40] shl 8); }
  { For some reason, this version below is more stable }
  count := Port[$40];
  count := count or (Port[$40] shl 8);

  TimerMS := ticks * 55 + (65536 - count) * 55 div 65536
end;



{ Similar to QB64's LIMIT }
procedure Limit(fps: integer);
begin
  delay(1000 div fps)
end;


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


procedure drawFPS;
begin
  print('FPS:' + i32str(lastFPS), 240, 0, $0E);
end;


procedure INIT;
begin
  initVGAMode;
  loadFont;
  initBuffer;
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
  randomize;
  done := false;

  fps := 0;
  lastFPS := 0;
  lastFPSTime := getTimer;

  dt := 0;
  lastTime := getTimer;
  newTime := lastTime;
  { deltaMS := 0;
  lastMS := timerMS; }

  for a:=0 to high(particles) do
    initParticle(particles[a]);

  repeat
    { limit(60); }

    { Call getTimer only once to prevent desync }
    newTime := getTimer;
    if newTime - lastTime > 0.0 then begin
      dt := newTime - lastTime;
      lastTime := newTime;
    end;

    { if timerMS - lastMS > 0.0 then begin
      deltaMS := TimerMS - lastMS;
      lastMS := TimerMS;
    end; }


    fps := fps+1;
    if Timer - lastFPSTime >= 1.0 then begin
      lastFPSTime := Timer;
      lastFPS := fps;
      fps := 1;
    end;

    update;
    draw;
  until done;

  freeBuffer;
  initTextMode;
end.