{ Bitmap rotation + scale render procedures }

interface

procedure initTrigLUT;
procedure sprPro(const image: PBitmap; const x, y: integer; angle: double; const transparencyKey: byte); { in degrees }
procedure sprPro2(
  const image: PBitmap;
  const x, y: integer;
  const scaleX, scaleY: double;
  angle: double;
  const transparencyKey: byte);
{ procedure sprProLUT(image: PBitmap; x, y: integer; scaleX, scaleY, angle: double; transparencyKey: byte); }
procedure sprProLUT(
  const image: PBitmap;
  const x, y: integer;
  const scaleX, scaleY: double;
  const angle10: integer;
  const transparencyKey: byte);


implementation

var
  sinLUT, cosLUT: array[0..35] of double;

procedure initTrigLUT;
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

procedure sprPro(const image: PBitmap; const x, y: integer; angle: double; const transparencyKey: byte);
const
  halfsqr2 = 0.70710678; { Math.sqrt(2) / 2 }
var
  sw, sh, cx, cy: integer;
  sa, ca, dx, dy: double;
  ix, iy: integer;
  srcX, srcY: integer;
  colour: byte;
begin
  if image = nil then exit;

  sw:=image^.width;
  sh:=image^.height;
  cx:=sw div 2;
  cy:=sh div 2;

  angle:=angle/180*pi;
  sa:=sin(-angle); { inverse rotation }
  ca:=cos(-angle);

  { bounding box }
  { for iy:=0 to sh-1 do
  for ix:=0 to sw-1 do begin }
  for iy:=trunc(cy-sh * halfsqr2) to trunc(cy+sh * halfsqr2) do
  for ix:=trunc(cx-sw * halfsqr2) to trunc(cx+sw * halfsqr2) do begin
    dx:=ix-cx;
    dy:=iy-cy;

    { inverse rotation }
    srcX:=round(dx*ca - dy*sa + cx);
    srcY:=round(dx*sa + dy*ca + cy);

    if (0<=srcX) and (srcX<sw) and (0<=srcY) and (srcY<sh) then begin
      colour := image^.data[srcY*sw + srcX];
      if colour <> transparencyKey then
        pset(x+ix, y+iy, colour);
    end;
  end;
end;


{ Laggy }
procedure sprPro2(
  const image: PBitmap;
  const x, y: integer;
  const scaleX, scaleY:
  double; angle: double;
  const transparencyKey: byte);
var
  sw, sh, cx, cy: integer;
  sa, ca: double;
  ix, iy: integer; { offset from image centre }
  srcX, srcY: integer;
  hw, hh: integer;
  colour: byte;
begin
  if image = nil then exit;

  sw:=image^.width;
  sh:=image^.height;
  cx:=sw div 2;
  cy:=sh div 2;

  angle:=angle/180*pi;
  sa:=sin(-angle); { inverse rotation }
  ca:=cos(-angle);

  hw:=trunc(sw*scaleX*abs(ca) + sh*scaleY*abs(sa));
  hh:=trunc(sw*scaleX*abs(sa) + sh*scaleY*abs(ca));

  { Debug bounding box }
  {
  pset(-trunc(sw/2 * scaleX), -trunc(sh/2*scaleY), $0E);
  pset( trunc(sw/2 * scaleX), -trunc(sh/2*scaleY), $0E);
  pset( trunc(sw/2 * scaleX),  trunc(sh/2*scaleY), $0E);
  pset(-trunc(sw/2 * scaleX),  trunc(sh/2*scaleY), $0E);
  }

  { bounding box }
  for iy:=-hh to hh do
  for ix:=-hw to hw do begin
    { scaling, then inverse rotation }
    srcX:=round((ix*ca - iy*sa) / scaleX + cx);
    srcY:=round((ix*sa + iy*ca) / scaleY + cy);

    if (0<=srcX) and (srcX<sw) and (0<=srcY) and (srcY<sh) then begin
      colour := image^.data[srcY*sw + srcX];
      if colour <> transparencyKey then
        pset(x+ix, y+iy, colour);
    end;
  end;
end;

{ Laggy despite with lookup tables }
procedure sprProLUT(
  const image: PBitmap;
  const x, y: integer;
  const scaleX, scaleY: double;
  const angle10: integer;
  const transparencyKey: byte);
var
  sw, sh, cx, cy: integer;
  sa, ca: double;
  ix, iy: integer; { offset from image centre }
  srcX, srcY: integer;
  hw, hh: integer;
  angleI32: integer;
  colour: byte;
begin
  if image = nil then exit;

  sw:=image^.width;
  sh:=image^.height;
  cx:=sw div 2;
  cy:=sh div 2;

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
      colour := image^.data[srcY*sw + srcX];
      if colour <> transparencyKey then
        pset(x+ix, y+iy, colour);
    end;
  end;
end;


end.