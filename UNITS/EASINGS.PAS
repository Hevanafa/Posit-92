{
  Easings utility unit
  Part of Posit-92 game engine
}

unit Easings;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

type
  TLerpTimer = record
    { active: boolean; }
    startTick, endTick: double;
  end;

procedure InitLerp(var lt: TLerpTimer; const startTick, duration: double);

{ t: current time, in seconds }
function GetLerpPerc(const lt: TLerpTimer; const t: double): double;

{ t: current time, in seconds }
function IsLerpComplete(const lt: TLerpTimer; const t: double): boolean;

function Linear(const a, z: double; perc: double): double;
function EaseOutQuad(const perc: double): double;
function LerpEaseOutQuad(const a, z, perc: double): double;


implementation

uses P92MATHS;

procedure InitLerp(var lt: TLerpTimer; const startTick, duration: double);
begin
  { lt.active := true; }
  lt.startTick := startTick;
  lt.endTick := startTick + duration;
end;

function GetLerpPerc(const lt: TLerpTimer; const t: double): double;
begin
  { if not lt.active then begin
    GetLerpPerc := 0.0;
    exit
  end; }

  GetLerpPerc := clamp((t - lt.startTick) / (lt.endTick - lt.startTick), 0.0, 1.0)
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

function LerpEaseOutQuad(const a, z, perc: double): double;
begin
  LerpEaseOutQuad := a + EaseOutQuad(perc) * (z - a)
end;

end.
