unit P92ANIMS;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

uses P92TEX;

type
  { Stateless sprite animation
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
  var sprite: TSprAnim;
  const tex: TTexture;
  const frameCount, frameWidth, frameHeight: word;
  const interval: double);

{
  t: current time, it can be either real time or gameTime, in seconds
  startTick gets reset if the sprite loops
}
procedure UpdateSprAnim(
  const sprite: TSprAnim;
  const t: double;
  var startTick: double;
  var frameIdxRef: integer);

procedure RewindSprAnim(
  var startTickRef: double;
  const startTick: double;
  var frameIdxRef: integer);

procedure DrawSprAnim(
  const sprite: TSprAnim;
  const frameIdx: integer;
  const x, y: integer);

function IsSprAnimCompleted(const sprite: TSprAnim; const startTick, t: double): boolean;


implementation

procedure InitSprAnim(
  var sprite: TSprAnim;
  const tex: TTexture;
  const frameCount, frameWidth, frameHeight: word;
  const interval: double);
begin
  sprite.texture := @tex;
  sprite.frameCount := frameCount;
  sprite.frameWidth := frameWidth;
  sprite.frameHeight := frameHeight;
  sprite.interval := interval;
  sprite.looping := true;

  { TODO: Sanity checks }
end;

procedure UpdateSprAnim(
  const sprite: TSprAnim;
  const t: double;
  var startTick: double;
  var frameIdxRef: integer);
begin
  if t >= startTick + sprite.interval then begin
    if frameIdxRef < sprite.frameCount - 1 then begin
      inc(frameIdxRef);
      startTick := startTick + sprite.interval
    end else if sprite.looping then begin
      frameIdxRef := 0;
      startTick := startTick + sprite.interval
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
  const sprite: TSprAnim;
  const frameIdx: integer;
  const x, y: integer);
var
  localFrameIdx: integer;
begin
  localFrameIdx := frameIdx;

  if not sprite.looping and (localFrameIdx >= sprite.frameCount) then
    localFrameIdx := sprite.frameCount - 1;

  SprRegion(
    sprite.texture^,
    sprite.frameWidth * localFrameIdx,
    0,
    sprite.frameWidth,
    sprite.frameHeight,
    x, y);
end;

function IsSprAnimCompleted(const sprite: TSprAnim; const startTick, t: double): boolean;
begin
  IsSprAnimCompleted := not sprite.looping
    and ((t - startTick) / sprite.interval >= sprite.frameCount);
end;

end.

