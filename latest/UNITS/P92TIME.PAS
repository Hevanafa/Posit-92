{
  Time-related unit
  Part of Posit-92 game engine
}

unit P92TIME;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

{ Ticks since the last boot }
function GetBIOSTicks: longint;

{ Get the seconds since midnight from the last boot }
function Timer: real;

{
  Higher resolution TIMER with microsecond precision
  Returns time in seconds
}
function GetTimer: real;

{ Similar to QB64's _LIMIT, but does the busy wait }
procedure Limit(const fps: integer);

procedure InitDeltaTime;
procedure UpdateDeltaTime;

function DeltaTime: double;


implementation

uses CRT, DOS;

{ Edit (19-05-2025): BIOS has the absolute ticks since the last boot }
var
  dt, newTime, lastTime: double; { in seconds }
  nextGameTick: double; { Used in `Limit()` }


function GetBIOSTicks: longint;
begin
  GetBIOSTicks := MemL[$0040:$006C]
end;


function Timer: real;
const
  PITFreq = 1193182.0 / 65536.0;
begin
  Timer := MemL[$0040:$006C] / PITFreq
end;


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


procedure Limit(const fps: integer);
var
  startTick: double;
begin
  startTick := getTimer;
  nextGameTick := startTick + 1.0 / fps;
  while GetTimer < nextGameTick do ;
end;

procedure InitDeltaTime;
begin
  dt := 0;
  lastTime := getTimer;
  newTime := lastTime;
end;

procedure UpdateDeltaTime;
begin
  { Call getTimer only once to prevent desync }
  newTime := GetTimer;
  if newTime - lastTime > 0.0 then begin
    dt := newTime - lastTime;
    lastTime := newTime;
  end;
end;

function DeltaTime: double;
begin
  DeltaTime := dt
end;

end.
