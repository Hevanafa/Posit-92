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

{
  Gets the Julian day number
  Used together with GetDate from DOS unit
}
function DateToJDN(const y, m, d: word): longint;

{
  Gets the time in seconds since epoch
  up to microsecond precision
}
function GetFullTimer: double;

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


function DateToJDN(const y, m, d: word): longint;
var
  a: longint;
begin
  a := (14 - m) div 12;

  DateToJDN :=
    (1461 * (y + 4800 - a)) div 4
    + (367 * (m + 12 * a - 2)) div 12
    - (3 * ((y + 4900 - a) div 100)) div 4
    + d - 32075
end;

function GetFullTimer: double;
const
  EpochJDN = 2440588;
var
  y, m, d, dayOfWeek: word;
  dateSinceEpoch: longint;
begin
  GetDate(y, m, d, dayOfWeek);
  dateSinceEpoch := DateToJDN(y, m, d) - EpochJDN;

  GetFullTimer := dateSinceEpoch * 86400.0 + GetTimer
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
