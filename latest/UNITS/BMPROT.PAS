{ Texture rotation + scale render procedures }

unit BMPROT;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

uses P92TEX;

{ angle: in degrees }
procedure SprRot(const image: TTexture; const x, y: integer; angle: double);

{
  Performs scaling and rotation on the fly (very heavy!)
  I recommend you to scale the image first, cache it, and then use SprRot instead

  angle: in degrees
}
procedure SprScaleRot(
  const image: TTexture;
  const x, y: integer;
  const scaleX, scaleY: double;
  angle: double);

{
  Similar to SprScaleRot but with lookup tables
  Perf note: Laggy despite with lookup tables
  angle: in degrees [0..35]
}
procedure SprScaleRotLUT(
  const image: TTexture;
  const x, y: integer;
  const scaleX, scaleY: double;
  const angle10: integer);


implementation

uses Logger, Conv, P92VGA;

var
  transparencyKey: byte;
  sinLUT, cosLUT: array[0..35] of double;

procedure InitTrigLUT;
var
  i: integer;
begin
  { Generate sine/cosine lookup table }
  for i := 0 to 35 do begin
    sinLUT[i] := sin(i * 10 * Pi / 180);
    cosLUT[i] := cos(i * 10 * Pi / 180);
    writeLog(i32str(i) + ' - ' + f32str(sinLUT[i]))
  end;
end;

procedure SprRot(const image: TTexture; const x, y: integer; angle: double);
const
  HalfSqrt2 = 0.70710678; { Math.sqrt(2) / 2 }
var
  sw, sh, cx, cy: integer;
  sa, ca, dx, dy: double;
  ix, iy: integer;
  srcX, srcY: integer;
  colour: byte;
begin
  sw := image.width;
  sh := image.height;
  cx := sw div 2;
  cy := sh div 2;

  angle:=angle/180*pi;
  sa:=sin(-angle); { inverse rotation }
  ca:=cos(-angle);

  { bounding box }
  for iy:=trunc(cy-sh * HalfSqrt2) to trunc(cy+sh * HalfSqrt2) do begin
    dy:=iy-cy;

    for ix:=trunc(cx-sw * HalfSqrt2) to trunc(cx+sw * HalfSqrt2) do begin
      dx:=ix-cx;

      { inverse rotation }
      srcX := round(dx*ca - dy*sa + cx);
      srcY := round(dx*sa + dy*ca + cy);

      if (0<=srcX) and (srcX<sw) and (0<=srcY) and (srcY<sh) then begin
        colour := image.data^[srcY*sw + srcX];

        if colour <> transparencyKey then
          AsmPSet(x+ix, y+iy, colour);
      end;
    end;
  end;
end;


procedure SprScaleRot(
  const image: TTexture;
  const x, y: integer;
  const scaleX, scaleY: double;
  angle: double);
var
  sw, sh, cx, cy: integer;
  sinth, costh: double;
  icx, icy: integer; { offset from image centre }
  srcX, srcY: integer;
  hw, hh: integer;
  colour: byte;
begin
  if (scaleX = 1) and (scaleY = 1) then begin
    SprRot(image, x, y, angle);
    exit
  end;

  sw := image.width;
  sh := image.height;
  cx := sw div 2;
  cy := sh div 2;

  angle := angle/180*pi;
  { inverse rotation }
  sinth := sin(-angle);
  costh := cos(-angle);

  hw:=trunc(sw*scaleX*abs(costh) + sh*scaleY*abs(sinth));
  hh:=trunc(sw*scaleX*abs(sinth) + sh*scaleY*abs(costh));

  { Debug bounding box }
  {
  pset(-trunc(sw/2 * scaleX), -trunc(sh/2*scaleY), $0E);
  pset( trunc(sw/2 * scaleX), -trunc(sh/2*scaleY), $0E);
  pset( trunc(sw/2 * scaleX),  trunc(sh/2*scaleY), $0E);
  pset(-trunc(sw/2 * scaleX),  trunc(sh/2*scaleY), $0E);
  }

  { bounding box }
  for icy:=-hh to hh do
    for icx:=-hw to hw do begin
      { scaling, then inverse rotation }
      srcX := round((icx*costh - icy*sinth) / scaleX + cx);
      srcY := round((icx*sinth + icy*costh) / scaleY + cy);

      if (0<=srcX) and (srcX<sw) and (0<=srcY) and (srcY<sh) then begin
        colour := image.data^[srcY*sw + srcX];

        if colour <> transparencyKey then
          AsmPSet(x+icx, y+icy, colour);
      end;
    end;
end;


procedure SprScaleRotLUT(
  const image: TTexture;
  const x, y: integer;
  const scaleX, scaleY: double;
  const angle10: integer);
var
  sw, sh, cx, cy: integer;
  sa, ca: double;
  ix, iy: integer; { offset from image centre }
  srcX, srcY: integer;
  hw, hh: integer;
  angleI32: integer;
  colour: byte;
begin
  sw := image.width;
  sh := image.height;
  cx := sw div 2;
  cy := sh div 2;

  { inverse rotation }
  angleI32:=angle10 mod 36;
  sa:=sinLUT[35-angleI32];
  ca:=cosLUT[35-angleI32];

  hw:=trunc(sw*scaleX*abs(ca) + sh*scaleY*abs(sa));
  hh:=trunc(sw*scaleX*abs(sa) + sh*scaleY*abs(ca));

  { bounding box }
  for iy:=-hh to hh do
  for ix:=-hw to hw do begin
    { scaling, then inverse rotation }
    srcX:=round((ix*ca - iy*sa) / scaleX + cx);
    srcY:=round((ix*sa + iy*ca) / scaleY + cy);

    if (0<=srcX) and (srcX<sw) and (0<=srcY) and (srcY<sh) then begin
      colour := image.data^[srcY*sw + srcX];
      if colour <> transparencyKey then
        pset(x+ix, y+iy, colour);
    end;
  end;
end;

begin
  transparencyKey := $0D;
  InitTrigLUT
end.
