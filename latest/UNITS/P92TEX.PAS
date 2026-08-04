{
  Software texture unit
  Part of Posit-92 game engine

  The key drawing procedures are:
  - Spr
  - SprRegion
  - SprFlipped

  The rest will be left unoptimised
}

unit P92TEX;

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

  PTexture = ^TTexture;
  TTexture = record
    width, height: word; { palsize }
    data: PByteArray;
  end;

procedure DefaultBMP(var tex: TTexture);

{
  Loads an indexed bitmap file into a TTexture
  This requires the bitmap to be an indexed 256 colours
}
procedure LoadBMP(var tex: TTexture; const filename: string);
procedure CloneBMP(const src: TTexture; var dest: TTexture);
procedure FreeBMP(var tex: TTexture);

procedure DrawBitmapInfo(const tex: TTexture);

procedure SprOpaque(const tex: TTexture);

{ Forwards call to AsmSpr
  Note that the max texture data is 64KB

  Any images bigger than that, use PascalSpr }
procedure Spr(const tex: TTexture; const x, y: integer);

procedure PascalSpr(const tex: TTexture; const x, y: integer);

{ Handle the edge cases
  Hot spot with inline ASM

  The maximum texture data size is 64KB }
procedure AsmSpr(const tex: TTexture; const x, y: integer);

{ Blit directly to the VGA memory }
procedure VGASpr(const tex: TTexture; const x, y: integer);

procedure SprScaled(const tex: TTexture; const x, y: integer; const scale: integer);

procedure SprTint(const tex: TTexture; const x, y: integer; const tint: byte);

{ Improved version of Spr with partial sprite drawing }
procedure SprRegion(
  const tex: TTexture;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);

procedure SprFlipped(const tex: TTexture; const x, y: integer; const flip: integer);


implementation

uses Logger, Conv, Panic, P92VGA;

var
  transparencyKey: byte;

procedure SetTransparencyKey(const value: byte);
begin
  transparencyKey := value
end;

procedure DefaultBMP(var tex: TTexture);
begin
  tex.width := 0;
  tex.height := 0;
  tex.data := nil;
end;

procedure LoadBMP(var tex: TTexture; const filename: string);
var
  f: file;
  buffer: array[1..256] of byte;
  row: integer;
  palsize: word;
  size: longint;
  start, padding: longint;
  rowOffset: longint;

begin
  if Assigned(tex.data) then begin
    WriteLog('LoadBMP: Warning: texture has been previously assigned');
    WriteLog('About to load "' + filename + '"');
    { FreeBMP(tex) }
  end;

  DefaultBMP(tex);

  assign(f, filename);
  {$I-} reset(f, 1); {$I+} { record size is 1 --> binary mode }
  if IOResult <> 0 then
    panicHalt('loadBMP: Couldn''t find "' + filename + '"!');

  seek(f, 18); blockRead(f, tex.width, 2);
  seek(f, 22); blockRead(f, tex.height, 2);
  seek(f, 50); blockRead(f, palsize, 2);

  size := tex.width * tex.height;
  getMem(tex.data, size);
  { tex^.palsize := palsize; }

{$IFDEF DEBUG}
  writeLog('Width:' + I32Str(tex.width));
  writeLog('Height:' + I32Str(tex.height));
  { writeLog('Palette:' + I32Str(tex^.palsize)); }
{$ENDIF}

  start := 54 + palsize * 4;
  if tex.width mod 4 = 0 then
    padding := 0
  else
    padding := 4 - tex.width mod 4;

{$IFDEF DEBUG}
  writeLog('Start:' + I32Str(start));
  writeLog('Padding:' + I32Str(padding));
{$ENDIF}

  for row := 0 to tex.height - 1 do begin
    seek(f, start + (row * (tex.width + padding)));
    blockRead(f, buffer, tex.width);

    {$IFDEF DEBUG}
      writeLog('Finished reading line ' + I32Str(row));
    {$ENDIF}

    { Read from bottom to top }
    rowOffset := (tex.height - row - 1) * tex.width;
    Move(buffer[1], tex.data^[rowOffset], tex.width);
  end;

  close(f)
end;

procedure CloneBMP(const src: TTexture; var dest: TTexture);
begin
  dest := src;
  { dest.data := nil; }
  move(src.data, dest.data, src.width * src.height)
end;

procedure FreeBMP(var tex: TTexture);
begin
  FreeMem(tex.data, tex.width * tex.height);
  tex.width := 0;
  tex.height := 0
end;

procedure DrawBitmapInfo(const tex: TTexture);
begin
  print('Width: ' + I32Str(tex.width), 10, 168, 15);
  print('Height: ' + I32Str(tex.height), 10, 176, 15);
  { print('Palette: ' + I32Str(tex^.palsize) + ' colours', 10, 184, 15) }
end;

procedure SprOpaque(const tex: TTexture);
var
  a, b: integer;
  rowOffset: word;
begin
  for b := 0 to tex.height - 1 do begin
    rowOffset := b * tex.width;

    for a := 0 to tex.width - 1 do
      AsmPSet(a, b, tex.data^[rowOffset + a]);
  end;
end;

procedure Spr(const tex: TTexture; const x, y: integer);
begin
  AsmSpr(tex, x, y)
end;

procedure PascalSpr(const tex: TTexture; const x, y: integer);
var
  srcX, srcY: integer;
  rowOffset, pxOffset: longint;

  startY, endY: integer;
  startX, endX: integer;
begin
  { Early exits }
  if (x >= VGAWidth) or (y >= VGAHeight) then exit;
  if (x + tex.width <= 0) or (y + tex.height <= 0) then exit;

  { Handle vertical clipping }
  startY := 0;
  endY := tex.height - 1;

  if y < 0 then startY := -y;
  if y + endY >= VGAHeight then endY := VGAHeight - 1 - y;

  { Handle horizontal clipping }
  startX := 0;
  endX := tex.width - 1;

  if x < 0 then startX := -x;
  if x + endX >= VGAWidth then endX := VGAWidth - 1 - x;

  { Begin loop }

  for srcY := startY to endY do begin
    rowOffset := srcY * tex.width;

    for srcX := startX to endX do begin
      pxOffset := rowOffset + srcX;

      if tex.data^[pxOffset] <> transparencyKey then
        AsmPSet(x+srcX, y+srcY, tex.data^[pxOffset]);
    end;
  end;
end;

procedure AsmSpr(const tex: TTexture; const x, y: integer);
var
  srcX, srcY: integer;
  rowOffset, pxOffset: longint;

  startY, endY: integer;
  startX, endX: integer;

  destOffset: word;
  drawCount: word;

  pixelData: pointer;
  srcAdd: word;
begin
  { Early exits }
  if (x >= VGAWidth) or (y >= VGAHeight) then exit;
  if (x + tex.width <= 0) or (y + tex.height <= 0) then exit;

  pixelData := tex.data;

  { Handle vertical clipping }
  startY := 0;
  endY := tex.height - 1;

  if y < 0 then startY := -y;
  if y + endY >= VGAHeight then endY := VGAHeight - 1 - y;

  { Handle horizontal clipping }
  startX := 0;
  endX := tex.width - 1;

  if x < 0 then startX := -x;
  if x + endX >= VGAWidth then endX := VGAWidth - 1 - x;

  { Begin loop }

  for srcY := startY to endY do begin
    destOffset := word(y + srcY) * VGAWidth + word(x + startX);
    drawCount := endX - startX + 1;
    srcAdd := word(srcY) * tex.width + startX;

    asm
      push ds

      les di, surface
      add di, destOffset

      { Load DH with transparencyKey }
      mov dh, transparencyKey

      { Load DS:SI with the source tex's data }
      lds si, pixelData
      add si, srcAdd
      mov cx, drawCount
      mov ah, dh

    @loop:
      lodsb
      cmp al, ah
      je @skip
      mov es:[di], al

    @skip:
      inc di
      dec cx
      jnz @loop

      pop ds
    end;
  end;
end;


procedure VGASpr(const tex: TTexture; const x, y: integer);
var
  a, b, pos: integer;
  rowOffset: longint;
begin
  for b := 0 to tex.height - 1 do begin
    if y + b >= DefaultVGAHeight then break;
    if y + b < 0 then continue;

    rowOffset := (y + b) * DefaultVGAWidth;

    for a := 0 to tex.width - 1 do begin
      if x + a >= DefaultVGAWidth then break;
      if x + a < 0 then continue;

      pos := a + b * tex.width;

      if tex.data^[pos] <> transparencyKey then
        Mem[$A000:rowOffset + (x+a)] := tex.data^[pos];
    end;
  end;
end;

procedure SprScaled(const tex: TTexture; const x, y: integer; const scale: integer);
var
  srcX, srcY, c, d: integer;
  destX, destY: integer; { top left corner of the scaled pixel }
  rowOffset, pxOffset: longint;
begin
  if scale = 0 then exit;
  if scale < 0 then PanicHalt('SprScaled: Scale cannot be negative!');

  for srcY := 0 to tex.height-1 do begin
    destY := y + srcY * scale;

    if destY >= VGAHeight then break;
    if destY < 0 then continue;

    rowOffset := srcY * tex.width;

    for srcX := 0 to tex.width-1 do begin
      destX := x + srcX * scale;

      if destX >= VGAWidth then break;
      if destX < 0 then continue;

      pxOffset := rowOffset + srcX;

      if tex.data^[pxOffset] = transparencyKey then continue;

      { Begin drawing the scaled pixels }
      for d := 0 to scale-1 do
        for c := 0 to scale-1 do
          AsmPSet(destX + c, destY + d, tex.data^[pxOffset]);

      { for d := 0 to scale-1 do begin
        if destY + d >= VGAHeight then break;
        if destY + d < 0 then continue;

	for c := 0 to scale-1 do begin
          if destX + c >= VGAWidth then break;
          if destX + c < 0 then continue;

          UnsafeAsmPSet(destX + c, destY + d, tex^.data[pxOffset]);
        end;
      end; }
    end;
  end;
end;


procedure SprTint(const tex: TTexture; const x, y: integer; const tint: byte);
var
  a, b: integer;
  rowOffset, pxOffset: longint;
begin
  for b := 0 to tex.height - 1 do begin
    rowOffset := b * tex.width;

    for a := 0 to tex.width - 1 do begin
      pxOffset := rowOffset + a;

      if tex.data^[pxOffset] <> transparencyKey then
        AsmPSet(x+a, y+b, tint);
    end;
  end;
end;

procedure SprRegion(
  const tex: TTexture;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);
var
  a, b: integer;
  rowOffset, pxOffset: longint;
begin
  for b := 0 to srcH - 1 do begin
    rowOffset := (srcY + b) * tex.width;

    for a := 0 to srcW - 1 do begin
      pxOffset := rowOffset + (srcX + a);

      if tex.data^[pxOffset] <> transparencyKey then
        AsmPSet(destX + a, destY + b, tex.data^[pxOffset]);
    end;
  end;
end;

procedure SprFlipped(const tex: TTexture; const x, y: integer; const flip: integer);
var
  row, col: integer;
  srcX, srcY: integer;
  pxOffset: longint;
  colour: byte;
begin
  case flip of
    SprFlipHorizontal: begin
      for row := 0 to tex.height - 1 do begin
        pxOffset := row * tex.width;

        for col := 0 to tex.width - 1 do begin
          srcX := (tex.width - 1) - col;
          colour := tex.data^[pxOffset + srcX];

          if colour <> transparencyKey then
            pset(x + col, y + row, colour);
        end;
      end;
    end;

    SprFlipVertical: begin
      for row := 0 to tex.height - 1 do begin
        pxOffset := srcY * tex.width;

        for col := 0 to tex.width - 1 do begin
          srcY := (tex.height - 1) - row;
          colour := tex.data^[pxOffset + col];

          if colour <> transparencyKey then
            pset(x + col, y + row, colour);
        end;
      end;
    end;

    SprFlipBoth: begin
      for row := 0 to tex.height - 1 do begin
        pxOffset := srcY * tex.width;

        for col := 0 to tex.width - 1 do begin
          srcX := (tex.width - 1) - col;
          srcY := (tex.height - 1) - row;

          colour := tex.data^[pxOffset + srcX];

          if colour <> transparencyKey then
            pset(x + col, y + row, colour);
        end;
      end;
    end
    else
      { Invalid state! }
  end;
end;

begin
  SetTransparencyKey($0D);
end.
