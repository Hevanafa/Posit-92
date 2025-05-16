unit Bitmap;

interface

type
  PBitmap = ^TBitmap;
  TBitmap = record
    width, height, palsize: word;
    data: array[0..0] of byte;
  end;

procedure loadBMP(var output: PBitmap; const filename: string);
procedure drawBMP(const image: PBitmap);
procedure freeBMP(var image: PBitmap);
procedure spr(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
procedure sprTint(const image: PBitmap; const x, y: integer; const transparencyKey, tint: byte);
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
procedure bitmapInfo(const image: PBitmap);


implementation

uses Logger, Conv, Panic, VGA;

const DEBUG = true;

var
  sinLUT, cosLUT: array[0..35] of double;

{ var makes it pass-by-reference }
procedure loadBMP(var output: PBitmap; const filename: string);
var
  f: file;
  buffer: array[1..256] of byte;
  bytesRead: word;
  a, b: integer;
  w, h, palsize, size: integer;
  start, padding: integer;

begin
  assign(f, filename);
  {$I-} reset(f, 1); {$I+} { record size is 1 --> binary mode }
  if IOResult <> 0 then
    panicHalt('loadBMP: Couldn''t find "' + filename + '"!');

  { blockRead(f, buffer, sizeOf(buffer), bytesRead); }
  { writeLn('Read ', bytesRead, ' bytes from sample.bmp'); }
  seek(f, 18); blockRead(f, w, 2);
  seek(f, 22); blockRead(f, h, 2);
  seek(f, 50); blockRead(f, palsize, 2);

  size := sizeOf(TBitmap) + (w * h) - 1;
  getMem(output, size);
  output^.width := w;
  output^.height := h;
  output^.palsize := palsize;
  { output^.size := w * h; }

  if debug then begin
    writeLog('Width:' + i32str(output^.width));
    writeLog('Height:' + i32str(output^.height));
    writeLog('Palette:' + i32str(output^.palsize));
  end;

  start := 54 + palsize * 4;
  if w mod 4 = 0 then
    padding := 0
  else
    padding := 4 - w mod 4;

  if debug then begin
    writeLog('Start:' + i32str(start));
    writeLog('Padding:' + i32str(padding));
  end;

  for b := 0 to h-1 do begin
    seek(f, start + (b * (w + padding)));
    blockRead(f, buffer, w);

    if debug then
      writeLog('Finished reading line ' + i32str(b));

    { for a:=1 to 256 do pset(a-1, h-b-1, buffer[a]); }
    { bottom to top }
    Move(buffer[1], output^.data[(h-b-1) * w], w);
  end;

  close(f)
end;

procedure drawBMP(const image: PBitmap);
var
  a, b: integer;
begin
  if image = nil then exit;
  for b := 0 to image^.height-1 do
  for a := 0 to image^.width-1 do
    pset(a, b, image^.data[a + b * image^.width]);
end;

procedure freeBMP(var image: PBitmap);
begin
  if image = nil then exit;
  freeMem(image, sizeOf(TBitmap) + (image^.width * image^.height) - 1);
  image := nil  { avoids dangling pointer }
end;

procedure spr(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
var
  a, b, pos: integer;
begin
  if image = nil then exit;
  for b := 0 to image^.height-1 do
  for a := 0 to image^.width-1 do begin
    pos := a + b * image^.width;
    if image^.data[pos] <> transparencyKey then
      pset(x+a, y+b, image^.data[pos]);
  end;
end;

procedure sprTint(const image: PBitmap; const x, y: integer; const transparencyKey, tint: byte);
var
  a, b, pos: integer;
begin
  if image = nil then exit;
  for b := 0 to image^.height-1 do
  for a := 0 to image^.width-1 do begin
    pos := a + b * image^.width;
    if image^.data[pos] <> transparencyKey then
      pset(x+a, y+b, tint);
  end;
end;

function deg2rad(deg: double): double;
begin
  deg2rad := deg / 180 * pi
end;

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


procedure bitmapInfo(const image: PBitmap);
begin
  if image = nil then begin
    print('image is nil!', 10, 168, 15);
    exit
  end;

  { print('File name:' + name, 10, 160, 15); }
  print('Width: ' + i32str(image^.width), 10, 168, 15);
  print('Height: ' + i32str(image^.height), 10, 176, 15);
  print('Palette: ' + i32str(image^.palsize) + ' colours', 10, 184, 15)
end;

end.
