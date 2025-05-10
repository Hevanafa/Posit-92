
uses
  CRT, DOS,
  Conv, FPS, Logger, Mouse, Timing, VGA;

type
  TParticle = record
    alive: boolean;
    x, y: single;
    vx, vy: single; { pixels per second }
  end;

const
  NUM_KEYS = 128;

var
  done: boolean;
  particles: array [0..99] of TParticle;

  keyDown: array[0..NUM_KEYS - 1] of boolean;
  oldKeyHandler: pointer;

procedure keyHandler; interrupt;
var
  scancode: byte;
  isBreak: boolean;
begin
  scancode := Port[$60];
  isBreak := (scancode and $80) <> 0;
  scancode := scancode and $7F; { mask break bit }

  if scancode < NUM_KEYS then
    keyDown[scancode] := not isBreak;

  { acknowledge interrupt }
  Port[$20] := $20
end;

procedure initKeyHandler;
begin
  getIntVec($09, oldKeyHandler);
  setIntVec($09, @keyHandler)
end;

procedure resetKeyHandler;
begin
  setIntVec($09, oldKeyHandler)
end;

function isKeyDown(scancode: byte): boolean;
begin
  isKeyDown := keyDown[scancode]
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
  updateMouse;

  if isKeyDown($01) then
    done := true;

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

  drawMouse;
  { debugMouse; }

  if isKeyDown($11) then
    print('W key is down', 0, 32, 15);

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

  resetMouse;
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.