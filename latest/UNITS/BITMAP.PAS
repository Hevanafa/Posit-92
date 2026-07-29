unit Bitmap;

{$IFDEF FPC}
{$MODE TP}
{$ENDIF}

interface

type
  TByteArray = array[0..0] of byte;

  PBitmap = ^TBitmap;
  TBitmap = record
    width, height, palsize: word;
    data: TByteArray;
  end;

procedure LoadBMP(var output: PBitmap; const filename: string);
procedure DrawBMP(const image: PBitmap);
procedure FreeBMP(var image: PBitmap);

procedure BitmapInfo(const image: PBitmap);

{ Forwards call to PascalSpr }
procedure Spr(const image: PBitmap; const x, y: integer);
procedure PascalSpr(const image: PBitmap; const x, y: integer);

procedure VGASpr(const image: PBitmap; const x, y: integer);

procedure SprScaled(const image: PBitmap; const x, y: integer; const scale: integer);

procedure SprTint(const image: PBitmap; const x, y: integer; const tint: byte);

procedure SprRegion(
  const image: PBitmap;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);

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

uses Logger, Conv, Panic, P92VGA;

const DEBUG = true;

var
  sinLUT, cosLUT: array[0..35] of double;
  transparencyKey: byte;

procedure SetTransparencyKey(const value: byte);
begin
  transparencyKey := value
end;

{ var makes it pass-by-reference }
procedure LoadBMP(var output: PBitmap; const filename: string);
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
    writeLog('Width:' + I32Str(output^.width));
    writeLog('Height:' + I32Str(output^.height));
    writeLog('Palette:' + I32Str(output^.palsize));
  end;

  start := 54 + palsize * 4;
  if w mod 4 = 0 then
    padding := 0
  else
    padding := 4 - w mod 4;

  if debug then begin
    writeLog('Start:' + I32Str(start));
    writeLog('Padding:' + I32Str(padding));
  end;

  for b := 0 to h-1 do begin
    seek(f, start + (b * (w + padding)));
    blockRead(f, buffer, w);

    if debug then
      writeLog('Finished reading line ' + I32Str(b));

    { for a:=1 to 256 do PSet(a-1, h-b-1, buffer[a]); }
    { bottom to top }
    Move(buffer[1], output^.data[(h-b-1) * w], w);
  end;

  close(f)
end;

procedure DrawBMP(const image: PBitmap);
var
  a, b: integer;
begin
  if image = nil then exit;
  for b := 0 to image^.height-1 do
  for a := 0 to image^.width-1 do
    PSet(a, b, image^.data[a + b * image^.width]);
end;

procedure FreeBMP(var image: PBitmap);
begin
  if image = nil then exit;
  freeMem(image, sizeOf(TBitmap) + (image^.width * image^.height) - 1);
  image := nil  { avoids dangling pointer }
end;

procedure Spr(const image: PBitmap; const x, y: integer);
begin
  PascalSpr(image, x, y)
end;

procedure PascalSpr(const image: PBitmap; const x, y: integer);
var
  srcX, srcY: integer;
  rowOffset, pxOffset: word;
begin
  if image = nil then exit;

  for srcY := 0 to image^.height-1 do begin
    rowOffset := srcY * image^.width;

    for srcX := 0 to image^.width-1 do begin
      pxOffset := rowOffset + srcX;

      if image^.data[pxOffset] <> transparencyKey then
        AsmPSet(x+srcX, y+srcY, image^.data[pxOffset]);
    end;
  end;
end;

procedure VGASpr(const image: PBitmap; const x, y: integer);
var
  a, b, pos: integer;
  rowOffset: word;
begin
  if image = nil then exit;

  for b := 0 to image^.height-1 do begin
    if y + b >= DefaultVGAHeight then break;
    if y + b < 0 then continue;

    rowOffset := (y + b) * DefaultVGAWidth;

    for a := 0 to image^.width-1 do begin
      if x + a >= DefaultVGAWidth then break;
      if x + a < 0 then continue;

      pos := a + b * image^.width;

      if image^.data[pos] <> transparencyKey then
        Mem[$A000:rowOffset + (x+a)] := image^.data[pos];
    end;
  end;
end;

procedure SprScaled(const image: PBitmap; const x, y: integer; const scale: integer);
var
  srcX, srcY, c, d: integer;
  destX, destY: integer; { top left corner of the scaled pixel }
  rowOffset, pxOffset: word;
begin
  if (image = nil) or (scale = 0) then exit;
  if scale < 0 then PanicHalt('SprScaled: Scale cannot be negative!');

  for srcY := 0 to image^.height-1 do begin
    destY := y + srcY * scale;

    if destY >= VGAHeight then break;
    if destY < 0 then continue;

    rowOffset := srcY * image^.width;

    for srcX := 0 to image^.width-1 do begin
      destX := x + srcX * scale;

      if destX >= VGAWidth then break;
      if destX < 0 then continue;

      pxOffset := rowOffset + srcX;

      if image^.data[pxOffset] = transparencyKey then continue;

      { Begin drawing the scaled pixels }
      for d := 0 to scale-1 do
        for c := 0 to scale-1 do
          AsmPSet(destX + c, destY + d, image^.data[pxOffset]);

      { for d := 0 to scale-1 do begin
        if destY + d >= VGAHeight then break;
        if destY + d < 0 then continue;

	for c := 0 to scale-1 do begin
          if destX + c >= VGAWidth then break;
          if destX + c < 0 then continue;

          UnsafeAsmPSet(destX + c, destY + d, image^.data[pxOffset]);
        end;
      end; }
    end;
  end;
end;


procedure SprTint(const image: PBitmap; const x, y: integer; const tint: byte);
var
  a, b: integer;
  rowOffset, pxOffset: word;
begin
  if image = nil then exit;

  for b := 0 to image^.height-1 do begin
    rowOffset := b * image^.width;

    for a := 0 to image^.width-1 do begin
      pxOffset := rowOffset + a;

      if image^.data[pxOffset] <> transparencyKey then
        AsmPSet(x+a, y+b, tint);
    end;
  end;
end;

{ Improved version of PascalSpr with partial sprite drawing }
procedure SprRegion(
  const image: PBitmap;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);
var
  a, b: integer;
  rowOffset, pxOffset: word;
begin
  if image = nil then exit;
  
  for b := 0 to srcH - 1 do begin
    rowOffset := (srcY + b) * image^.width;

    for a := 0 to srcW - 1 do begin
      pxOffset := rowOffset + (srcX + a);

      if image^.data[pxOffset] <> transparencyKey then
        AsmPSet(destX + a, destY + b, image^.data[pxOffset]);
    end;
  end;
end;

procedure initTrigLUT;
var
  i: integer;
begin
  { Generate sine/cosine lookup table }
  for i := 0 to 35 do begin
    sinLUT[i] := sin(i * 10 * Pi / 180);
    cosLUT[i] := cos(i * 10 * Pi / 180);
    writeLog(I32Str(i) + ' - ' + F32Str(sinLUT[i]))
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
        PSet(x+ix, y+iy, colour);
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
  PSet(-trunc(sw/2 * scaleX), -trunc(sh/2*scaleY), $0E);
  PSet( trunc(sw/2 * scaleX), -trunc(sh/2*scaleY), $0E);
  PSet( trunc(sw/2 * scaleX),  trunc(sh/2*scaleY), $0E);
  PSet(-trunc(sw/2 * scaleX),  trunc(sh/2*scaleY), $0E);
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
        PSet(x+ix, y+iy, colour);
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
        PSet(x+ix, y+iy, colour);
    end;
  end;
end;

procedure BitmapInfo(const image: PBitmap);
begin
  if image = nil then begin
    print('image is nil!', 10, 168, 15);
    exit
  end;

  { print('File name:' + name, 10, 160, 15); }
  print('Width: ' + I32Str(image^.width), 10, 168, 15);
  print('Height: ' + I32Str(image^.height), 10, 176, 15);
  print('Palette: ' + I32Str(image^.palsize) + ' colours', 10, 184, 15)
end;

begin
  SetTransparencyKey($0D);
end.
