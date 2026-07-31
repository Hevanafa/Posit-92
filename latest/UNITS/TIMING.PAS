unit Timing;

{$IFDEF FPC}
{$MODE TP}
{$ENDIF}

interface

function GetBIOSTicks: Longint;
function Timer: real;
function GetTimer: real;
function GetTimerMS: Longint;

procedure Limit(const fps: integer);

procedure InitDeltaTime;
procedure UpdateDeltaTime;

function DeltaTime: double;


implementation

uses CRT, DOS;

{ Edit (19-05-2025): BIOS has the absolute ticks since the last boot }
var
  dt, newTime, lastTime: double; { in seconds }
  { deltaMS, lastMS: longint; }

  nextGameTick: double; { Used in `Limit()` }

{ Ticks since the last boot }
function GetBIOSTicks: Longint;
begin
  GetBIOSTicks := MemL[$0040:$006C]
end;

{ Seconds since the midnight from the last boot }
function Timer: real;
const
  PITFreq = 1193182.0 / 65536.0;
begin
  Timer := MemL[$0040:$006C] / PITFreq
end;

{ Higher resolution TIMER with microsecond precision }
function GetTimer: real;
const
  PITFreq = 1193182.0 / 65536.0;
var
  counter: word;
  ticks: longint;
  pending: boolean;
begin
  { Begin atomic section }
  asm cli end;

  { Latch & read PIT channel 0 }
  Port[$43] := $00;
  counter := Port[$40];
  counter := counter or (Port[$40] shl 8);  { Read low & high bytes }

  { Read BIOS tick count }
  ticks := MemL[$0040:$006C];

  { Check if IRQ0 is pending (PIT wrapped but ISR hasn't run yet) }
  Port[$20] := $0A;
  pending := (Port[$20] and $01) <> 0;

  { End atomic section }
  asm sti end;

  GetTimer := (ticks + (65536 - counter) / 65536) / PITFreq;
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

procedure InitDeltaTime;
begin
  dt := 0;
  lastTime := getTimer;
  newTime := lastTime;
  { deltaMS := 0;
  lastMS := timerMS; }
end;

procedure UpdateDeltaTime;
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

function DeltaTime: double;
begin
  DeltaTime := dt
end;

end.
