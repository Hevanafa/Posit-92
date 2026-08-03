unit Bitmap;

{$IFDEF FPC}{$MODE TP}{$ENDIF}
{$DEFINE DEBUG}

interface

const
  SprFlipHorizontal = 1;
  SprFlipVertical = 2;
  SprFlipBoth = SprFlipHorizontal or SprFlipVertical;

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..0] of byte;

  PBitmap = ^TBitmap;
  TBitmap = record
    width, height: word; { palsize }
    data: PByteArray;
  end;

procedure DefaultBMP(var image: TBitmap);
procedure LoadBMP(var image: TBitmap; const filename: string);
procedure CloneBMP(const src: TBitmap; var dest: TBitmap);
procedure FreeBMP(var image: TBitmap);

procedure DrawBitmapInfo(const image: TBitmap);

procedure SprOpaque(const image: TBitmap);

{ Forwards call to PascalSpr }
procedure Spr(const image: TBitmap; const x, y: integer);
procedure PascalSpr(const image: TBitmap; const x, y: integer);

{ Blit directly to the VGA memory }
procedure VGASpr(const image: TBitmap; const x, y: integer);

procedure SprScaled(const image: TBitmap; const x, y: integer; const scale: integer);

procedure SprTint(const image: TBitmap; const x, y: integer; const tint: byte);

procedure SprRegion(
  const image: TBitmap;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);

procedure SprFlipped(const image: TBitmap; const x, y: integer; const flip: integer);


implementation

uses Logger, Conv, Panic, P92VGA;

var
  transparencyKey: byte;

procedure SetTransparencyKey(const value: byte);
begin
  transparencyKey := value
end;

procedure DefaultBMP(var image: TBitmap);
begin
  image.width := 0;
  image.height := 0;
  image.data := nil;
end;

procedure LoadBMP(var image: TBitmap; const filename: string);
var
  f: file;
  buffer: array[1..256] of byte;
  row: integer;
  palsize: word;
  size: longint;
  start, padding: longint;
  rowOffset: longint;

begin
  assign(f, filename);
  {$I-} reset(f, 1); {$I+} { record size is 1 --> binary mode }
  if IOResult <> 0 then
    panicHalt('loadBMP: Couldn''t find "' + filename + '"!');

  seek(f, 18); blockRead(f, image.width, 2);
  seek(f, 22); blockRead(f, image.height, 2);
  seek(f, 50); blockRead(f, palsize, 2);

  size := image.width * image.height;
  getMem(image.data, size);
  { image^.palsize := palsize; }

{$IFDEF DEBUG}
  writeLog('Width:' + I32Str(image.width));
  writeLog('Height:' + I32Str(image.height));
  { writeLog('Palette:' + I32Str(image^.palsize)); }
{$ENDIF}

  start := 54 + palsize * 4;
  if image.width mod 4 = 0 then
    padding := 0
  else
    padding := 4 - image.width mod 4;

{$IFDEF DEBUG}
  writeLog('Start:' + I32Str(start));
  writeLog('Padding:' + I32Str(padding));
{$ENDIF}

  for row := 0 to image.height - 1 do begin
    seek(f, start + (row * (image.width + padding)));
    blockRead(f, buffer, image.width);

    {$IFDEF DEBUG}
      writeLog('Finished reading line ' + I32Str(row));
    {$ENDIF}

    { Read from bottom to top }
    rowOffset := (image.height - row - 1) * image.width;
    Move(buffer[1], image.data^[rowOffset], image.width);
  end;

  close(f)
end;

procedure CloneBMP(const src: TBitmap; var dest: TBitmap);
begin
  dest := src;
  { dest.data := nil; }
  move(src.data, dest.data, src.width * src.height)
end;

procedure FreeBMP(var image: TBitmap);
begin
  FreeMem(image.data, image.width * image.height);
end;

procedure DrawBitmapInfo(const image: TBitmap);
begin
  print('Width: ' + I32Str(image.width), 10, 168, 15);
  print('Height: ' + I32Str(image.height), 10, 176, 15);
  { print('Palette: ' + I32Str(image^.palsize) + ' colours', 10, 184, 15) }
end;

procedure SprOpaque(const image: TBitmap);
var
  a, b: integer;
  rowOffset: word;
begin
  for b := 0 to image.height - 1 do begin
    rowOffset := b * image.width;

    for a := 0 to image.width - 1 do
      AsmPSet(a, b, image.data^[rowOffset + a]);
  end;
end;

procedure Spr(const image: TBitmap; const x, y: integer);
begin
  PascalSpr(image, x, y)
end;

procedure PascalSpr(const image: TBitmap; const x, y: integer);
var
  srcX, srcY: integer;
  rowOffset, pxOffset: word;
begin
  for srcY := 0 to image.height - 1 do begin
    rowOffset := srcY * image.width;

    for srcX := 0 to image.width - 1 do begin
      pxOffset := rowOffset + srcX;

      if image.data^[pxOffset] <> transparencyKey then
        AsmPSet(x+srcX, y+srcY, image.data^[pxOffset]);
    end;
  end;
end;

procedure VGASpr(const image: TBitmap; const x, y: integer);
var
  a, b, pos: integer;
  rowOffset: word;
begin
  for b := 0 to image.height - 1 do begin
    if y + b >= DefaultVGAHeight then break;
    if y + b < 0 then continue;

    rowOffset := (y + b) * DefaultVGAWidth;

    for a := 0 to image.width - 1 do begin
      if x + a >= DefaultVGAWidth then break;
      if x + a < 0 then continue;

      pos := a + b * image.width;

      if image.data^[pos] <> transparencyKey then
        Mem[$A000:rowOffset + (x+a)] := image.data^[pos];
    end;
  end;
end;

procedure SprScaled(const image: TBitmap; const x, y: integer; const scale: integer);
var
  srcX, srcY, c, d: integer;
  destX, destY: integer; { top left corner of the scaled pixel }
  rowOffset, pxOffset: word;
begin
  if scale = 0 then exit;
  if scale < 0 then PanicHalt('SprScaled: Scale cannot be negative!');

  for srcY := 0 to image.height-1 do begin
    destY := y + srcY * scale;

    if destY >= VGAHeight then break;
    if destY < 0 then continue;

    rowOffset := srcY * image.width;

    for srcX := 0 to image.width-1 do begin
      destX := x + srcX * scale;

      if destX >= VGAWidth then break;
      if destX < 0 then continue;

      pxOffset := rowOffset + srcX;

      if image.data^[pxOffset] = transparencyKey then continue;

      { Begin drawing the scaled pixels }
      for d := 0 to scale-1 do
        for c := 0 to scale-1 do
          AsmPSet(destX + c, destY + d, image.data^[pxOffset]);

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


procedure SprTint(const image: TBitmap; const x, y: integer; const tint: byte);
var
  a, b: integer;
  rowOffset, pxOffset: word;
begin
  for b := 0 to image.height - 1 do begin
    rowOffset := b * image.width;

    for a := 0 to image.width - 1 do begin
      pxOffset := rowOffset + a;

      if image.data^[pxOffset] <> transparencyKey then
        AsmPSet(x+a, y+b, tint);
    end;
  end;
end;

{ Improved version of PascalSpr with partial sprite drawing }
procedure SprRegion(
  const image: TBitmap;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);
var
  a, b: integer;
  rowOffset, pxOffset: word;
begin
  for b := 0 to srcH - 1 do begin
    rowOffset := (srcY + b) * image.width;

    for a := 0 to srcW - 1 do begin
      pxOffset := rowOffset + (srcX + a);

      if image.data^[pxOffset] <> transparencyKey then
        AsmPSet(destX + a, destY + b, image.data^[pxOffset]);
    end;
  end;
end;

procedure SprFlipped(const image: TBitmap; const x, y: integer; const flip: integer);
var
  row, col: integer;
  srcX, srcY: integer;
  pxOffset: longint;
  colour: byte;
begin
  case flip of
    SprFlipHorizontal: begin
      for row := 0 to image.height - 1 do
        for col := 0 to image.width - 1 do begin
          srcX := (image.width - 1) - col;
          pxOffset := row * image.width + srcX;
          colour := image.data^[pxOffset];

          if image.data^[pxOffset] <> transparencyKey then
            pset(x + col, y + row, colour);
        end;
    end;
    else
      { Not implemented! }
  end;
end;

begin
  SetTransparencyKey($0D);
end.
