{
  Easing utility unit
  Part of Posit-92 game engine
}

unit P92EASE;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

type
  TEaseFunc = function(perc: double): double;
  TLerpTimer = record
    startTick, endTick: double;
  end;

procedure InitLerp(var lt: TLerpTimer; const startTick, duration: double);

{
  startTick: in seconds
  duration: in seconds
  t: current time, in seconds
}
function GetPerc(startTick, duration, t: double): double;

{ t: current time, in seconds }
function IsLerpComplete(const lt: TLerpTimer; const t: double): boolean;

function EaseOutQuad(const perc: double): double; far;

function Linear(const a, z: double; perc: double): double;


implementation

uses P92MATHS;

procedure InitLerp(var lt: TLerpTimer; const startTick, duration: double);
begin
  { lt.active := true; }
  lt.startTick := startTick;
  lt.endTick := startTick + duration;
end;

function GetPerc(startTick, duration, t: double): double;
var
  endTick: double;
begin
  endTick := startTick + duration;

  GetPerc := Clamp((t - startTick) / (endTick - startTick), 0.0, 1.0)
end;

function IsLerpComplete(const lt: TLerpTimer; const t: double): boolean;
begin
  IsLerpComplete := t >= lt.endTick
end;

function Linear(const a, z: double; perc: double): double;
begin
  perc := clamp(perc, 0.0, 1.0);
  Linear := a + perc * (z - a)
end;

function EaseOutQuad(const perc: double): double;
begin
  EaseOutQuad := 1 - (1 - perc) * (1 - perc)
end;

function LerpEased(a, z, perc: double; ease: TEaseFunc): double;
begin
  if not assigned(ease) then
    PanicHalt('LerpEased: ease is not defined!');

  LerpEased := a + (z - a) * ease(perc)
end;

end.
