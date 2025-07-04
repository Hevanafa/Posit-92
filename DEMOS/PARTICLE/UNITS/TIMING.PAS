unit Timing;

interface

{ Edit (19-05-2025): BIOS has the absolute ticks since the last boot }
var
  dt, newTime, lastTime: double; { in seconds }
  { deltaMS, lastMS: longint; }

function GetTicks: Longint;
function Timer: real;
function GetTimer: real;
function GetTimerMS: Longint;
procedure Limit(const fps: integer);
procedure initDeltaTime;
procedure updateDeltaTime;

implementation

uses crt, dos;

var
  nextGameTick: double; { Used in `Limit()` }

{ Ticks since the last boot }
function GetTicks: Longint;
begin
  getTicks := MemL[$0040:$006C]
end;

{ Seconds since the midnight from the last boot }
function Timer: real;
begin
  Timer := MemL[$0040:$006C] / 18.2065
end;

{ Higher resolution TIMER with microsecond precision }
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

function GetTimerMS: Longint;
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

  GetTimerMS := ticks * 55 + (65536 - count) * 55 div 65536
end;

{ Similar to QB64's _LIMIT }
procedure Limit(const fps: integer);
var
  startTick: double;
begin
  { delay(1000 div fps) }
  startTick := getTimer;
  nextGameTick := startTick + 1.0 / fps;
  while getTimer < nextGameTick do ;
end;

procedure initDeltaTime;
begin
  dt := 0;
  lastTime := getTimer;
  newTime := lastTime;
  { deltaMS := 0;
  lastMS := timerMS; }
end;

procedure updateDeltaTime;
begin
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
end;


end.
