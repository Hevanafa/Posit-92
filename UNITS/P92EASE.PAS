{
  Easing utility unit
  Part of Posit-92 game engine
}

unit P92EASE;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

type
  TEaseFunc = function(perc: double): double;

{
  startTick: in seconds
  duration: in seconds
  t: current time, in seconds
}
function GetPerc(startTick, duration, t: double): double;

{
  a: start value
  z: end value (inclusive)
  perc: lerp percentage, can be obtained from GetPerc
}
function Lerp(a, z, perc: double): double;

{
  a: start value
  z: end value (inclusive)
  perc: lerp percentage, can be obtained from GetPerc
}
function LerpEased(a, z, perc: double; ease: TEaseFunc): double;

{ Easing functions }

function EaseOutQuad(perc: double): double; far;


implementation

uses P92MATHS, P92PANIC;

function GetPerc(startTick, duration, t: double): double;
begin
  if duration = 0.0 then begin
    GetPerc := 1.0;
    exit
  end;

  GetPerc := Clamp((t - startTick) / duration, 0.0, 1.0)
end;

function Lerp(a, z, perc: double): double;
begin
  perc := clamp(perc, 0.0, 1.0);
  Lerp := a + perc * (z - a)
end;

function LerpEased(a, z, perc: double; ease: TEaseFunc): double;
begin
  if not assigned(ease) then
    PanicHalt('LerpEased: ease function is not supplied!');

  perc := Clamp(perc, 0.0, 1.0);
  LerpEased := a + ease(perc) * (z - a)
end;

function EaseOutQuad(perc: double): double;
begin
  EaseOutQuad := 1 - (1 - perc) * (1 - perc)
end;

end.
