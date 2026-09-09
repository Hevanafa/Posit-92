unit P92ANIMS;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

uses P92TEX;

type
  { Stateless sprite animator
    Requires external frame index & start tick variables }
  TSprAnim = record
    texture: PTexture;

    frameCount: word;
    frameWidth: word;
    frameHeight: word;

    { frame interval in seconds }
    interval: double;
    looping: boolean;
  end;

{
  tex:
  - Must be a horizontal strip,
  - Texture pixel data must be 64KB or below
}
procedure InitSprAnim(
  var anim: TSprAnim;
  const tex: TTexture;
  const frameCount, frameWidth, frameHeight: word;
  const interval: double);

{
  t: current time in seconds, it can be either real time or gameTime
  startTick: reset when a looping animation wraps to the first frame
}
procedure UpdateSprAnim(
  const anim: TSprAnim;
  const t: double;
  var startTick: double;
  var frameIdx: integer);

{
  Rewinds only the external animation state
}
procedure RewindSprAnim(
  const newStartTick: double;
  var startTick: double;
  var frameIdx: integer);

procedure DrawSprAnim(
  const anim: TSprAnim;
  const x, y: integer;
  const frameIdx: integer);

{
  t: current time in seconds
  frameIdx: external animation state
}
function IsSprAnimCompleted(
  const anim: TSprAnim;
  const t: double;
  const frameIdx: integer
): boolean;


implementation

procedure InitSprAnim(
  var anim: TSprAnim;
  const tex: TTexture;
  const frameCount, frameWidth, frameHeight: word;
  const interval: double);
begin
  anim.texture := @tex;
  anim.frameCount := frameCount;
  anim.frameWidth := frameWidth;
  anim.frameHeight := frameHeight;
  anim.interval := interval;
  anim.looping := true;

  { TODO: Sanity checks }
end;

procedure UpdateSprAnim(
  const anim: TSprAnim;
  const t: double;
  var startTick: double;
  var frameIdx: integer);
begin
  if t >= startTick + anim.interval then begin
    if frameIdx < anim.frameCount - 1 then begin
      inc(frameIdx);
      startTick := startTick + anim.interval
    end else if anim.looping then begin
      frameIdx := 0;
      startTick := startTick + anim.interval
    end;
  end;
end;

procedure RewindSprAnim(
  const newStartTick: double;
  var startTick: double;
  var frameIdx: integer);
begin
  startTick := newStartTick;
  frameIdx := 0
end;

procedure DrawSprAnim(
  const anim: TSprAnim;
  const x, y: integer;
  const frameIdx: integer);
var
  localFrameIdx: integer;
begin
  localFrameIdx := frameIdx;

  if not anim.looping and (localFrameIdx >= anim.frameCount) then
    localFrameIdx := anim.frameCount - 1;

  SprRegion(
    anim.texture^,
    anim.frameWidth * localFrameIdx,
    0,
    anim.frameWidth,
    anim.frameHeight,
    x, y);
end;

function IsSprAnimCompleted(
  const anim: TSprAnim;
  const t: double;
  const frameIdx: integer
): boolean;
begin
  IsSprAnimCompleted := not anim.looping
    and (frameIdx >= anim.frameCount);
end;

end.

