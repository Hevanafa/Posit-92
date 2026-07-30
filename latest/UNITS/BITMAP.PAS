unit Bitmap;

{$IFDEF FPC}{$MODE TP}{$ENDIF}
{$DEFINE DEBUG}

interface

type
  TByteArray = array[0..0] of byte;

  PBitmap = ^TBitmap;
  TBitmap = record
    width, height: word; { palsize }
    data: TByteArray;
  end;

procedure LoadBMP(var output: PBitmap; const filename: string);
procedure CloneBMP(var src, dest: PBitmap);
procedure FreeBMP(var image: PBitmap);

procedure DrawBitmapInfo(const image: PBitmap);

procedure SprOpaque(const image: PBitmap);

{ Forwards call to PascalSpr }
procedure Spr(const image: PBitmap; const x, y: integer);
procedure PascalSpr(const image: PBitmap; const x, y: integer);

{ Blit directly to the VGA memory }
procedure VGASpr(const image: PBitmap; const x, y: integer);

procedure SprScaled(const image: PBitmap; const x, y: integer; const scale: integer);

procedure SprTint(const image: PBitmap; const x, y: integer; const tint: byte);

procedure SprRegion(
  const image: PBitmap;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);


implementation

uses Logger, Conv, Panic, P92VGA;

var
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
  { bytesRead: word; }
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

  size := sizeOf(TBitmap) + (w * h);
  getMem(output, size);
  output^.width := w;
  output^.height := h;
  { output^.palsize := palsize; }
  { output^.size := w * h; }

{$IFDEF DEBUG}
  writeLog('Width:' + I32Str(output^.width));
  writeLog('Height:' + I32Str(output^.height));
  { writeLog('Palette:' + I32Str(output^.palsize)); }
{$ENDIF}

  start := 54 + palsize * 4;
  if w mod 4 = 0 then
    padding := 0
  else
    padding := 4 - w mod 4;

{$IFDEF DEBUG}
  writeLog('Start:' + I32Str(start));
  writeLog('Padding:' + I32Str(padding));
{$ENDIF}

  for b := 0 to h-1 do begin
    seek(f, start + (b * (w + padding)));
    blockRead(f, buffer, w);

    {$IFDEF DEBUG}
      writeLog('Finished reading line ' + I32Str(b));
    {$ENDIF}

    { for a:=1 to 256 do PSet(a-1, h-b-1, buffer[a]); }
    { bottom to top }
    Move(buffer[1], output^.data[(h-b-1) * w], w);
  end;

  close(f)
end;

procedure CloneBMP(var src, dest: PBitmap);
begin
  if src = nil then exit;
  if dest <> nil then FreeBMP(dest);

  move(src, dest, sizeof(src))
end;

procedure FreeBMP(var image: PBitmap);
begin
  if image = nil then exit;

  FreeMem(image, sizeOf(TBitmap) + (image^.width * image^.height));
  image := nil  { avoids dangling pointer }
end;

procedure DrawBitmapInfo(const image: PBitmap);
begin
  if image = nil then begin
    print('image is nil!', 10, 168, 15);
    exit
  end;

  { print('File name:' + name, 10, 160, 15); }
  print('Width: ' + I32Str(image^.width), 10, 168, 15);
  print('Height: ' + I32Str(image^.height), 10, 176, 15);
  { print('Palette: ' + I32Str(image^.palsize) + ' colours', 10, 184, 15) }
end;

procedure SprOpaque(const image: PBitmap);
var
  a, b: integer;
  rowOffset: word;
begin
  if image = nil then exit;

  for b := 0 to image^.height-1 do begin
    rowOffset := b * image^.width;

    for a := 0 to image^.width-1 do
      AsmPSet(a, b, image^.data[rowOffset + a]);
  end;
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

begin
  SetTransparencyKey($0D);
end.
