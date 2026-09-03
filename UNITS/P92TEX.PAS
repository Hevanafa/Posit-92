{
  Software texture unit
  Part of Posit-92 game engine
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

procedure DefaultTex(var tex: TTexture);

{
  Loads an indexed bitmap file into a TTexture
  This requires the bitmap to be an indexed 256 colours

  If this error occurred: "200: division by zero"

  Try increasing the buffer capacity within this procedure, especially
  when processing a sprite with a width larger than buffer
}
procedure LoadTex(var tex: TTexture; const filename: string);

procedure CreateTex(var tex: TTexture; const width, height: word);
procedure CloneTex(const src: TTexture; var dest: TTexture);
procedure FreeTex(var tex: TTexture);

{ For debugging }
procedure DrawTexInfo(const tex: TTexture);

{ Begin drawing procedures }

procedure SprOpaque(const tex: TTexture);

{ Forwards call to AsmSpr
  Note that the max texture data is 64KB

  Any images bigger than that, use PascalSpr }
procedure Spr(const tex: TTexture; const x, y: integer);

procedure SprBase(const tex: TTexture; const x, y: integer);

{$IFNDEF P92_MODE_X}
{ Handle the edge cases
  Hot spot with inline ASM

  The maximum texture data size is 64KB }
procedure SprFast(const tex: TTexture; const x, y: integer);
{$ENDIF}

{ Blit directly to the VGA memory, not yet supported for Mode X }
procedure VGASpr(const tex: TTexture; const x, y: integer);

procedure SprStretch(const tex: TTexture; const x, y, w, h: integer);

procedure SprScaled(const tex: TTexture; const x, y: integer; const scaleX, scaleY: integer);
{ Forwards call to SprStretch }
procedure SprScaledWithStretch(const tex: TTexture; const x, y: integer; const scale: integer);

{ Copied from SprFast, only the pixel plotter is different }
procedure SprTint(const tex: TTexture; const x, y: integer; const tint: byte);

procedure SprRegionBase(
  const tex: TTexture;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);

procedure SprRegion(
  const tex: TTexture;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);

{ Copied from SprRegion, only the pixel plotter is different }
procedure SprRegionTint(
  const tex: TTexture;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer;
  const tint: byte
);

procedure SprFlipped(const tex: TTexture; const x, y: integer; const flip: integer);


implementation

uses
  P92LOG, P92CONV, P92PANIC, P92VGA
{$IFDEF P92_MODE_X}
  , P92MODEX
{$ENDIF}
  ;

var
  transparencyKey: byte;

procedure SetTransparencyKey(const value: byte);
begin
  transparencyKey := value
end;

procedure DefaultTex(var tex: TTexture);
begin
  tex.width := 0;
  tex.height := 0;
  tex.data := nil;
end;

procedure LoadTex(var tex: TTexture; const filename: string);
var
  f: file;
  buffer: array[1..512] of byte;
  row: integer;
  palsize: word;
  size: longint;
  start, padding: longint;
  rowOffset: longint;
begin
  if Assigned(tex.data) then begin
    WriteLog('LoadTex: Warning: texture has been previously assigned');
    WriteLog('About to load "' + filename + '"');
    { FreeTex(tex) }
  end;

  DefaultTex(tex);

  assign(f, filename);
  {$I-} reset(f, 1); {$I+} { record size is 1 --> binary mode }
  if IOResult <> 0 then
    PanicHalt('LoadTex: Couldn''t find "' + filename + '"!');

  seek(f, 18); blockRead(f, tex.width, 2);
  seek(f, 22); blockRead(f, tex.height, 2);
  seek(f, 50); blockRead(f, palsize, 2);

  size := tex.width * tex.height;
  GetMem(tex.data, size);
  { tex^.palsize := palsize; }

  {$IFDEF DEBUG}
  WriteLog('Width : ' + I32Str(tex.width));
  WriteLog('Height: ' + I32Str(tex.height));
  WriteLog('Size  : ' + I32Str(size));
  { writeLog('Palette:' + I32Str(tex^.palsize)); }
  {$ENDIF}

  start := 54 + palsize * 4;
  if tex.width mod 4 = 0 then
    padding := 0
  else
    padding := 4 - tex.width mod 4;

  {$IFDEF DEBUG}
  WriteLog('Start:' + I32Str(start));
  WriteLog('Padding:' + I32Str(padding));
  {$ENDIF}

  for row := 0 to tex.height - 1 do begin
    Seek(f, start + (row * (tex.width + padding)));
    BlockRead(f, buffer, tex.width);

    {$IFDEF DEBUG}
    WriteLog('LoadTex: BlockRead line ' + I32Str(row));
    {$ENDIF}

    { Read from bottom to top }
    rowOffset := (tex.height - row - 1) * tex.width;
    Move(buffer[1], tex.data^[rowOffset], tex.width);
  end;

  Close(f)
end;

procedure CreateTex(var tex: TTexture; const width, height: word);
begin
  tex.width := width;
  tex.height := height;
  GetMem(tex.data, width * height);
  FillChar(tex.data, width * height, $00);
end;

procedure CloneTex(const src: TTexture; var dest: TTexture);
begin
  dest := src;
  { dest.data := nil; }
  move(src.data, dest.data, src.width * src.height)
end;

procedure FreeTex(var tex: TTexture);
begin
  if Assigned(tex.data) then
    FreeMem(tex.data, tex.width * tex.height);

  tex.width := 0;
  tex.height := 0
end;

procedure DrawTexInfo(const tex: TTexture);
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
{$IFDEF P92_MODE_X}
  PascalSpr(tex, x, y);
{$ELSE}
  SprFast(tex, x, y)
{$ENDIF}
end;

procedure SprBase(const tex: TTexture; const x, y: integer);
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
      {$IFDEF P92_MODE_X}
        P92MODEX.PSet(x + srcX, y + srcY, tex.data^[pxOffset]);
      {$ELSE}
        AsmPSet(x+srcX, y+srcY, tex.data^[pxOffset]);
      {$ENDIF}
    end;
  end;
end;

{$IFNDEF P92_MODE_X}
procedure SprFast(const tex: TTexture; const x, y: integer);
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
  if (x > clipEndX) or (y > clipEndY) then exit;
  if (x + tex.width - 1 < clipStartX) or (y + tex.height - 1 < clipStartY) then exit;

  pixelData := tex.data;

  { Handle vertical clipping }
  startY := 0;
  endY := tex.height - 1;

  if y < clipStartY then startY := clipStartY - y;
  if y + endY > clipEndY then endY := clipEndY - y;

  { Handle horizontal clipping }
  startX := 0;
  endX := tex.width - 1;

  if x < clipStartX then startX := clipStartX - x;
  if x + endX > clipEndX then endX := clipEndX - x;

  { Begin loop }

  for srcY := startY to endY do begin
    destOffset := word(y + srcY) * VGAWidth + word(x + startX);
    drawCount := endX - startX + 1;
    srcAdd := word(srcY) * tex.width + startX;

    asm
      push ds

      les di, backBuffer
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
{$ENDIF}


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

procedure SprStretchBase(const tex: TTexture; const x, y, w, h: integer);
var
  srcX, srcY: integer;
  destX, destY: integer;
  a, b: integer;
  colour: byte;
begin
  if (w = 0) or (h = 0) then exit;
  if w < 0 then PanicHalt('SprStretch: Negative width is not supported');
  if h < 0 then PanicHalt('SprStretch: Negative height is not supported');

  for destY := 0 to h - 1 do begin
    srcY := (destY * tex.height) div h;
    b := y + destY;

    for destX := 0 to w - 1 do begin
      srcX := (destX * tex.width) div w;
      a := x + destX;

      colour := tex.data^[srcY * tex.width + srcX];

      if colour <> transparencyKey then
        AsmPSet(a, b, colour);
    end;
  end;
end;

procedure SprStretch(const tex: TTexture; const x, y, w, h: integer);
var
  srcX, srcY: integer;
  destX, destY: integer;

  startX, endX: integer;
  startY, endY: integer;

  srcRowOffset: word;
  pixelData: PByteArray;

  localTransparencyKey: byte;

  { Final coordinates, used in AsmPSet }
  a, b: integer;
  colour: byte;
begin
  if (w = 0) or (h = 0) then exit;
  if w < 0 then PanicHalt('SprStretch: Negative width is not supported');
  if h < 0 then PanicHalt('SprStretch: Negative height is not supported');

  { Handle clipping }

  startX := 0;
  endX := w - 1;
  startY := 0;
  endY := h - 1;

  if x < 0 then startX := -x;
  if y < 0 then startY := -y;
  if x + endX >= VGAWidth then endX := VGAWidth - 1 - x;
  if y + endY >= VGAHeight then endY := VGAHeight - 1 - y;

  if (startX > endX) or (startY > endY) then exit;

  pixelData := tex.data;

  localTransparencyKey := transparencyKey;

  for destY := startY to endY do begin
    srcY := (destY * tex.height) div h;
    srcRowOffset := srcY * tex.width;
    b := (y + destY) * VGAWidth;

    for destX := startX to endX do begin
      srcX := (destX * tex.width) div w;
      a := x + destX;

      colour := pixelData^[srcRowOffset + srcX];

      if colour <> transparencyKey then
        backBuffer^[b + a] := colour;
    end;
  end;
end;

procedure SprScaled(const tex: TTexture; const x, y: integer; const scaleX, scaleY: integer);
var
  srcX, srcY, c, d: integer;
  destX, destY: integer; { top left corner of the scaled pixel }
  rowOffset, pxOffset: longint;
begin
  if (scaleX = 0) or (scaleY = 0) then exit;
  if scaleX < 0 then PanicHalt('SprScaled: ScaleX cannot be negative!');
  if scaleY < 0 then PanicHalt('SprScaled: ScaleY cannot be negative!');

  for srcY := 0 to tex.height-1 do begin
    destY := y + srcY * scaleY;

    if destY >= VGAHeight then break;
    if destY < 0 then continue;

    rowOffset := srcY * tex.width;

    for srcX := 0 to tex.width-1 do begin
      destX := x + srcX * scaleX;

      if destX >= VGAWidth then break;
      if destX < 0 then continue;

      pxOffset := rowOffset + srcX;

      if tex.data^[pxOffset] = transparencyKey then continue;

      { Begin drawing the scaled pixels }
      for d := 0 to scaleY-1 do
        for c := 0 to scaleX-1 do
          AsmPSet(destX + c, destY + d, tex.data^[pxOffset]);
    end;
  end;
end;

procedure SprScaledWithStretch(const tex: TTexture; const x, y: integer; const scale: integer);
begin
  SprStretch(tex, x, y, tex.width * scale, tex.height * scale);
end;

procedure SprTint(const tex: TTexture; const x, y: integer; const tint: byte);
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
  if (x > clipEndX) or (y > clipEndY) then exit;
  if (x + tex.width - 1 < clipStartX) or (y + tex.height - 1 < clipStartY) then exit;

  pixelData := tex.data;

  { Handle vertical clipping }
  startY := 0;
  endY := tex.height - 1;

  if y < clipStartY then startY := clipStartY - y;
  if y + endY > clipEndY then endY := clipEndY - y;

  { Handle horizontal clipping }
  startX := 0;
  endX := tex.width - 1;

  if x < clipStartX then startX := clipStartX - x;
  if x + endX > clipEndX then endX := clipEndX - x;

  { Begin loop }

  for srcY := startY to endY do begin
    destOffset := word(y + srcY) * VGAWidth + word(x + startX);
    drawCount := endX - startX + 1;
    srcAdd := word(srcY) * tex.width + startX;

    asm
      push ds

      les di, backBuffer
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

      mov al, tint
      mov es:[di], al

    @skip:
      inc di
      dec cx
      jnz @loop

      pop ds
    end;
  end;
end;

procedure SprRegionBase(
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

procedure SprRegion(
  const tex: TTexture;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);
var
  localTransparencyKey: byte;

  { all these are inclusive }
  startX, endX, startY, endY: integer;

  srcOffsetX, srcOffsetY: integer;

  a, b: integer;

  srcRowBase: word;
  { pixel offset }
  srcPxOffset: word;
  destRowBase: word;

  pixelData: PByteArray;
begin
  { Handle clipping logic }
  startX := destX;
  startY := destY;
  endX := destX + srcW - 1;
  endY := destY + srcH - 1;

  if startX < clipStartX then startX := clipStartX;
  if startY < clipStartY then startY := clipStartY;
  if endX > clipEndX then endX := clipEndX;
  if endY > clipEndY then endY := clipEndY;

  if (startX > endX) or (startY > endY) then exit;

  srcOffsetX := startX - destX;
  srcOffsetY := startY - destY;

  localTransparencyKey := transparencyKey;
  pixelData := tex.data;

  for b := startY to endY do begin
    srcRowBase := (srcY + srcOffsetY + (b - startY)) * tex.width;
    srcPxOffset := srcRowBase + srcX + srcOffsetX;
    destRowBase := b * VGAWidth + startX;

    asm
    push es
    push ds

    les di, backBuffer
    add di, destRowBase

    lds si, pixelData
    add si, srcPxOffset

    mov cx, endX
    sub cx, startX
    inc cx

    mov dh, localTransparencyKey

    @x_loop:
      lodsb
      cmp al, dh
      je @skip
      mov es:[di], al

    @skip:
      inc di
      loop @x_loop

    pop ds
    pop es
    end;
  end;
end;


procedure SprRegionTint(
  const tex: TTexture;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer;
  const tint: byte
);
var
  localTransparencyKey: byte;

  { all these are inclusive }
  startX, endX, startY, endY: integer;

  srcOffsetX, srcOffsetY: integer;

  a, b: integer;

  srcRowBase: word;
  { pixel offset }
  srcPxOffset: word;
  destRowBase: word;

  pixelData: PByteArray;
begin
  { Handle clipping logic }
  startX := destX;
  startY := destY;
  endX := destX + srcW - 1;
  endY := destY + srcH - 1;

  if startX < clipStartX then startX := clipStartX;
  if startY < clipStartY then startY := clipStartY;
  if endX > clipEndX then endX := clipEndX;
  if endY > clipEndY then endY := clipEndY;

  if (startX > endX) or (startY > endY) then exit;

  srcOffsetX := startX - destX;
  srcOffsetY := startY - destY;

  localTransparencyKey := transparencyKey;
  pixelData := tex.data;

  for b := startY to endY do begin
    srcRowBase := (srcY + srcOffsetY + (b - startY)) * tex.width;
    srcPxOffset := srcRowBase + srcX + srcOffsetX;
    destRowBase := b * VGAWidth + startX;

    asm
    push es
    push ds

    les di, backBuffer
    add di, destRowBase

    lds si, pixelData
    add si, srcPxOffset

    mov cx, endX
    sub cx, startX
    inc cx

    mov dh, localTransparencyKey

    @x_loop:
      lodsb
      cmp al, dh
      je @skip

      mov al, tint
      mov es:[di], al

    @skip:
      inc di
      loop @x_loop

    pop ds
    pop es
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
