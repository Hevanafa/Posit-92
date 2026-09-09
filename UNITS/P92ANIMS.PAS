unit P92ANIMS;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

uses P92TEX;

type
  { Stateless sprite animation
    Requires 2 variables: frame index, start tick }
  TSpriteAnim = record
    texture: PTexture;

    frameCount: word;
    frameWidth, frameHeight: word;
    interval: double;  { in seconds }
    looping: boolean;
  end;

{
  tex: Must be a horizontal strip, max pixel data: 64KB
}
procedure InitSpriteAnim(
  var sprite: TSpriteAnim;
  const tex: TTexture;
  const frameCount, frameWidth, frameHeight: word;
  const interval: double);

{
  t: current time, it can be either real time or gameTime, in seconds
}
procedure UpdateSpriteAnim(
  const sprite: TSpriteAnim;
  const t: double;
  var startTick: double;
  var frameIdxRef: integer);

procedure RewindSpriteAnim(
  var startTickRef: double;
  const startTick: double;
  var frameIdxRef: integer);

procedure DrawSpriteAnim(
  const sprite: TSpriteAnim;
  const frameIdx: integer;
  const x, y: integer);


implementation

procedure InitSpriteAnim(
  var sprite: TSpriteAnim;
  const tex: TTexture;
  const frameCount, frameWidth, frameHeight: word;
  const interval: double);
begin
  sprite.texture := @tex;
  sprite.frameCount := frameCount;
  sprite.frameWidth := frameWidth;
  sprite.frameHeight := frameHeight;
  sprite.interval := interval;
  sprite.looping := true
end;

procedure UpdateSpriteAnim(
  const sprite: TSpriteAnim;
  const t: double;
  var startTick: double;
  var frameIdxRef: integer);
begin

end;

procedure RewindSpriteAnim(var startTickRef:double;const startTick:double;var frameIdxRef:integer);
begin

end;

procedure DrawSpriteAnim(const sprite:TSpriteAnim;const frameIdx:integer;const x,y:integer);
begin

end;

end.

