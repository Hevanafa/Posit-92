{
  Software texture unit specific to Mode X
  Part of Posit-92 game engine

  Deprecated: Will be removed, use P92TEX instead
}

unit XBitmap;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

type
  PTexture = ^TTexture;
  TTexture = record
    width, height, palsize: word;
    data: array[0..0] of byte;
  end;

procedure loadBMP(var output: PTexture; const filename: string);
procedure drawBMP(const tex: PTexture);
procedure freeBMP(var tex: PTexture);
procedure spr(const tex: PTexture; const x, y: integer; const transparencyKey: byte);
procedure sprTint(const tex: PTexture; const x, y: integer; const transparencyKey, tint: byte);
procedure sprPro(const tex: PTexture; const x, y: integer; angle: double; const transparencyKey: byte); { in degrees }
procedure sprPro2(
  const tex: PTexture;
  const x, y: integer;
  const scaleX, scaleY: double;
  angle: double;
  const transparencyKey: byte);
procedure bitmapInfo(const tex: PTexture);


implementation

uses Logger, Conv, Panic, ModeX;

{ var makes it pass-by-reference }
procedure loadBMP(var output: PTexture; const filename: string);
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

  size := sizeOf(TTexture) + (w * h) - 1;
  getMem(output, size);
  output^.width := w;
  output^.height := h;
  output^.palsize := palsize;

  {$IFDEF DEBUG}
  writeLog('Width:' + i32str(output^.width));
  writeLog('Height:' + i32str(output^.height));
  writeLog('Palette:' + i32str(output^.palsize));
  {$ENDIF}

  start := 54 + palsize * 4;
  if w mod 4 = 0 then
    padding := 0
  else
    padding := 4 - w mod 4;

  {$IFDEF DEBUG}
  writeLog('Start:' + i32str(start));
  writeLog('Padding:' + i32str(padding));
  {$ENDIF}

  for b := 0 to h-1 do begin
    seek(f, start + (b * (w + padding)));
    blockRead(f, buffer, w);

    {$IFDEF DEBUG}
    writeLog('Finished reading line ' + i32str(b));
	{$ENDIF}

    Move(buffer[1], output^.data[(h-b-1) * w], w);
  end;

  close(f)
end;

procedure drawBMP(const tex: PTexture);
var
  a, b: integer;
begin
  if tex = nil then exit;
  for b := 0 to tex^.height-1 do
  for a := 0 to tex^.width-1 do
    PSet(a, b, tex^.data[a + b * tex^.width]);
end;

procedure freeBMP(var tex: PTexture);
begin
  if tex = nil then exit;
  freeMem(tex, sizeOf(TTexture) + (tex^.width * tex^.height) - 1);
  tex := nil  { avoids dangling pointer }
end;

procedure spr(const tex: PTexture; const x, y: integer; const transparencyKey: byte);
var
  a, b, pos: integer;
begin
  if tex = nil then exit;
  for b := 0 to tex^.height-1 do
  for a := 0 to tex^.width-1 do begin
    pos := a + b * tex^.width;
    if tex^.data[pos] <> transparencyKey then
      PSet(x+a, y+b, tex^.data[pos]);
  end;
end;

procedure sprTint(const tex: PTexture; const x, y: integer; const transparencyKey, tint: byte);
var
  a, b, pos: integer;
begin
  if tex = nil then exit;
  for b := 0 to tex^.height-1 do
  for a := 0 to tex^.width-1 do begin
    pos := a + b * tex^.width;
    if tex^.data[pos] <> transparencyKey then
      PSet(x+a, y+b, tint);
  end;
end;

procedure sprPro(const tex: PTexture; const x, y: integer; angle: double; const transparencyKey: byte);
const
  halfsqr2 = 0.70710678; { Math.sqrt(2) / 2 }
var
  sw, sh, cx, cy: integer;
  sa, ca, dx, dy: double;
  ix, iy: integer;
  srcX, srcY: integer;
  colour: byte;
begin
  if tex = nil then exit;

  sw:=tex^.width;
  sh:=tex^.height;
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
      colour := tex^.data[srcY*sw + srcX];
      if colour <> transparencyKey then
        PSet(x+ix, y+iy, colour);
    end;
  end;
end;


{ Laggy }
procedure sprPro2(
  const tex: PTexture;
  const x, y: integer;
  const scaleX, scaleY:
  double; angle: double;
  const transparencyKey: byte);
var
  sw, sh, cx, cy: integer;
  sa, ca: double;
  ix, iy: integer; { offset from tex centre }
  srcX, srcY: integer;
  hw, hh: integer;
  colour: byte;
begin
  if tex = nil then exit;

  sw:=tex^.width;
  sh:=tex^.height;
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
      colour := tex^.data[srcY*sw + srcX];
      if colour <> transparencyKey then
        PSet(x+ix, y+iy, colour);
    end;
  end;
end;


procedure bitmapInfo(const tex: PTexture);
begin
  if tex = nil then begin
    Print('tex is nil!', 10, 168, 15);
    exit
  end;

  { Print('File name:' + name, 10, 160, 15); }
  Print('Width: ' + i32str(tex^.width), 10, 168, 15);
  Print('Height: ' + i32str(tex^.height), 10, 176, 15);
  Print('Palette: ' + i32str(tex^.palsize) + ' colours', 10, 184, 15)
end;


end.
