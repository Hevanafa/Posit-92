unit Easings;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

type
  TLerpTimer = record
    active: boolean;
    startTick, endTick: double;
  end;

procedure initLerpReal(var lt: TLerpTimer; const duration: double);
function getLerpPercReal(const lt: TLerpTimer): double;
function isLerpCompleteReal(const lt: TLerpTimer): boolean;

function linear(const a, z: double; perc: double): double;
function easeOutQuad(const perc: double): double;
function lerpEaseOutQuad(const a, z, perc: double): double;


implementation

uses Maths, Timing;

procedure initLerpReal(var lt: TLerpTimer; const duration: double);
var
  now: double;
begin
  now := getTimer;

  lt.active := true;
  lt.startTick := now;
  lt.endTick := now + duration;
end;

function getLerpPercReal(const lt: TLerpTimer): double;
begin
  if not lt.active then begin
    getLerpPercReal := 0.0;
    exit
  end;

  getLerpPercReal := clamp((getTimer - lt.startTick) / (lt.endTick - lt.startTick), 0.0, 1.0)
end;

function isLerpCompleteReal(const lt: TLerpTimer): boolean;
begin
  isLerpCompleteReal := getTimer >= lt.endTick
end;

function linear(const a, z: double; perc: double): double;
begin
  perc := clamp(perc, 0.0, 1.0);
  linear := a + perc * (z - a)
end;

function easeOutQuad(const perc: double): double;
begin
  easeOutQuad := 1 - (1 - perc) * (1 - perc)
end;

function lerpEaseOutQuad(const a, z, perc: double): double;
begin
  lerpEaseOutQuad := a + easeOutQuad(perc) * (z - a)
end;

end.
