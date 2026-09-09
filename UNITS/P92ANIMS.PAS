unit P92ANIMS;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

uses P92TEX;

type
  { Stateless sprite animator
    Requires 2 variables: frame index, start tick }
  TSprAnim = record
    texture: PTexture;

    frameCount: word;
    frameWidth: word;
    frameHeight: word;

    { in seconds }
    interval: double;
    looping: boolean;
  end;

{
  tex: Must be a horizontal strip, max pixel data: 64KB
}
procedure InitSprAnim(
  var anim: TSprAnim;
  const tex: TTexture;
  const frameCount, frameWidth, frameHeight: word;
  const interval: double);

{
  t: current time, it can be either real time or gameTime, in seconds
  startTick gets reset if the sprite loops
}
procedure UpdateSprAnim(
  const anim: TSprAnim;
  const t: double;
  var startTick: double;
  var frameIdxRef: integer);

{
  This procedure only rewinds the state variables
}
procedure RewindSprAnim(
  var startTickRef: double;
  const startTick: double;
  var frameIdxRef: integer);

procedure DrawSprAnim(
  const anim: TSprAnim;
  const frameIdx: integer;
  const x, y: integer);

function IsSprAnimCompleted(const anim: TSprAnim; const startTick, t: double): boolean;


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
  var frameIdxRef: integer);
begin
  if t >= startTick + anim.interval then begin
    if frameIdxRef < anim.frameCount - 1 then begin
      inc(frameIdxRef);
      startTick := startTick + anim.interval
    end else if anim.looping then begin
      frameIdxRef := 0;
      startTick := startTick + anim.interval
    end;
  end;
end;

procedure RewindSprAnim(
  var startTickRef: double;
  const startTick: double;
  var frameIdxRef: integer);
begin
  startTickRef := startTick;
  frameIdxRef := 0
end;

procedure DrawSprAnim(
  const anim: TSprAnim;
  const frameIdx: integer;
  const x, y: integer);
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

function IsSprAnimCompleted(const anim: TSprAnim; const startTick, t: double): boolean;
begin
  IsSprAnimCompleted := not anim.looping
    and ((t - startTick) / anim.interval >= anim.frameCount);
end;

end.

