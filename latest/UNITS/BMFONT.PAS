unit BMFont;

{$IFDEF FPC}
{$MODE TP}
{$ENDIF}

interface

uses Bitmap;

type
  PBMFontGlyph = ^TBMFontGlyph;
  { Record types in Turbo Pascal aren't padded by default }
  TBMFontGlyph = record
    id: word;
    x, y, width, height: word;  { 2, 4, 6, 8 }
    xoffset, yoffset: integer;  { 10, 12 }
    xadvance: integer; { 14 }
    { page, chnl: byte; }
  end;

  PBMFont = ^TBMFont;
  TBMFont = record
    glyphs: array[0..255] of TBMFontGlyph;
    lineHeight: word;
    bitmap: TBitmap;
  end;

procedure DefaultBMFont(var font: TBMFont);

{ This calls DefaultBMFont internally }
procedure LoadBMFont(var font: TBMFont; const filename: string);
{ This also frees the bitmap handle }
procedure FreeBMFont(var font: TBMFont);

procedure CloneBMFont(const src: TBMFont; var dest: TBMFont);

{ Returns xadvance }
function PrintBMFontGlyph(const font: TBMFont; const ch: char; const x, y: integer): integer;
procedure PrintBMFont(const font: TBMFont; const text: string; const x, y: integer);

function PrintBMFontGlyphTint(const font: TBMFont; const ch: char; const x, y: integer; const tint: byte): integer;
procedure PrintBMFontTint(const font: TBMFont; const text: string; const x, y: integer; const tint: byte);

{ Returns accumulated xadvance }
function MeasureBMFont(const font: TBMFont; const text: string): integer;

procedure SetTransparencyKey(const value: byte);


implementation

uses Conv, Logger, Panic, P92STR, P92VGA;

var
  transparencyKey: byte;

procedure ParseBMFontGlyph(var destFont: TBMFont; line: string);
var
  newGlyph: TBMFontGlyph;
  pairs: array[0..11] of string;
  pairCount: word;
  b: word;
  kv: array[0..1] of string; { key-value pair }
  glyphID: integer;
begin
  while Contains(line, '  ') do
    line := ReplaceAll(line, '  ', ' ');

  { Parse the whole line first, then check bounds }
  glyphID := -1;
  fillChar(newGlyph, sizeof(TBMFontGlyph), 0);

  { assign glyph info }
  pairCount := Split(line, ' ', pairs);

  for b:=0 to pairCount-1 do begin
    Split(pairs[b], '=', kv);

    { case-of can't be used with strings in TP7 }
    if kv[0] = 'id' then begin
      glyphID := parseInt(kv[1]);

      { writeLog('ID:' + i32str(glyphID)); }
      newGlyph.id := glyphID;
    end
    else if kv[0] = 'x' then newGlyph.x := parseInt(kv[1])
    else if kv[0] = 'y' then newGlyph.y := parseInt(kv[1])
    else if kv[0] = 'width' then newGlyph.width := parseInt(kv[1])
    else if kv[0] = 'height' then newGlyph.height := parseInt(kv[1])
    else if kv[0] = 'xoffset' then newGlyph.xoffset := parseInt(kv[1])
    else if kv[0] = 'yoffset' then newGlyph.yoffset := parseInt(kv[1])
    else if kv[0] = 'xadvance' then newGlyph.xadvance := parseInt(kv[1]);
  end;

  if (low(destFont.glyphs) <= newGlyph.id) and
      (newGlyph.id <= high(destFont.glyphs)) then
    destFont.glyphs[newGlyph.id] := newGlyph;
end;

procedure DefaultBMFont(var font: TBMFont);
var
  len: integer;
begin
  len := high(font.glyphs) - Low(font.glyphs) + 1;
  FillChar(font.glyphs, SizeOf(TBMFontGlyph) * len, 0);
  font.lineHeight := 0;
  DefaultBMP(font.bitmap);
end;

procedure LoadBMFont(var font: TBMFont; const filename: string);
var
  b: integer;
  f: text;

  count: word;
  line: string;
  pairs: array[0..11] of string;
  pairCount: word;
  kv: array[0..1] of string; { key-value pair }

  bitmapPath: string;
begin
  WriteLog('LoadBMFont: Loading font from ' + filename);

  DefaultBMFont(font);

  assign(f, filename);
  {$I-} reset(f); {$I+}
  if IOResult <> 0 then
    panicHalt('loadBMFont: Couldn''t find "' + filename + '"!');

  count := 0;

  { First pass }
  while not eof(f) do begin
    readln(f, line);

    while Contains(line, '  ') do
      line := ReplaceAll(line, '  ', ' ');

    if StartsWith(line, 'common') then begin
      pairCount := Split(line, ' ', pairs);
      for b:=0 to pairCount-1 do begin
        Split(pairs[b], '=', kv);
        if kv[0] = 'lineHeight' then
          font.lineHeight := parseInt(kv[1]);
      end;
    end;

    if StartsWith(line, 'page') then begin
      pairCount := Split(line, ' ', pairs);
      for b:=0 to pairCount-1 do begin
        Split(pairs[b], '=', kv);
        if kv[0] = 'file' then
          bitmapPath := ReplaceAll(kv[1], '"', '');
      end;
    end;
  end;

  { Second pass: parse the glyphs }
  close(f);
  reset(f);

  while not eof(f) do begin
    readln(f, line);

    if StartsWith(line, 'char') then
      ParseBMFontGlyph(font, line);
  end;
  close(f);

  LoadBMP(font.bitmap, bitmapPath);
  writeLog('Loaded ' + i32str(count) + ' glyphs');
end;


procedure FreeBMFont(var font: TBMFont);
var
  a, count: word;
  len: word;
begin
  len := high(font.glyphs) + 1;
  fillchar(font.glyphs, sizeof(TBMFontGlyph) * len, 0);
  font.lineHeight := 0;

  FreeBMP(font.bitmap)
end;

procedure CloneBMFont(const src: TBMFont; var dest: TBMFont);
begin
  dest := src;
  CloneBMP(src.bitmap, dest.bitmap);
end;

function PrintBMFontGlyph(const font: TBMFont; const ch: char; const x, y: integer): integer;
var
  row, col: integer;
  rowBase: longint;
  colour: byte;
  { Avoid copying of the record type }
  g: PBMFontGlyph;

  startRow, endRow, startCol, endCol: integer;
  drawX, drawY: integer;
  { vgaRowOffset: word; }

  screenX, screenY: integer;
  colCount: word;
begin
  g := @(font.glyphs[ord(ch)]);
  PrintBMFontGlyph := g^.xadvance;

  { Edge case: Handle space }
  if (g^.width = 0) and (g^.height = 0) then exit;

  drawX := x + g^.xoffset;
  drawY := y + g^.yoffset;

  { Handle early exit }
  if (drawX >= VGAWidth) or (drawY >= VGAHeight) then exit;
  if (drawX + g^.width <= 0) or (drawY + g^.height <= 0) then exit;

  { Clip to visible region }
  startCol := 0;
  endCol := g^.width - 1;
  startRow := 0;
  endRow := g^.height - 1;

  if drawX < 0 then startCol := -drawX;
  if drawX + endCol >= VGAWidth then
    endCol := VGAWidth - 1 - drawX;

  if drawY < 0 then startRow := -drawY;
  if drawY + endRow >= VGAHeight then
    endRow := VGAHeight - 1 - drawY;

  { Begin loop }
  {
  for row := startRow to endRow do begin
    rowBase := (g^.y + row) * font.bitmap.width + g^.x;

    for col := startCol to endCol do begin
      colour := font.bitmap.data^[rowBase + col];

      if colour <> transparencyKey then
        AsmPSet(drawX + col, drawY + row, colour);
    end;
  end;
  }

  { Same as above, but with a precomputed offset }
  {
  for row := startRow to endRow do begin
    rowBase := (g^.y + row) * font.bitmap.width + g^.x;
    vgaRowOffset := (drawY + row) * VGAWidth + drawX;

    for col := startCol to endCol do begin
      colour := font.bitmap.data^[rowBase + col];

      if colour <> transparencyKey then
        AsmPSetOffset(vgaRowOffset + col, colour);
    end;
  end;
  }

for row := startRow to endRow do begin
  rowBase := (g^.y + row) * font.bitmap.width + g^.x + startCol;
  screenY := drawY + row;
  screenX := drawX + startCol;
  colCount := endCol - startCol + 1;

  asm
    { Load ES:DI to surface + screen offset }
    les di, surface
    mov ax, screenY
    mov bx, VGAWidth
    mul bx
    add ax, screenX
    add di, ax

    { Load DS:SI to bitmap data + rowBase }
    { TODO: Load DS:SI with font.bitmap.data }
    add si, rowBase

    mov cx, colCount

  @col_loop:
    lodsb
    cmp al, transparencyKey
    je @skip
    mov es:[di], al

  @skip:
    inc di
    loop @col_loop
  end;
end;
end;

procedure PrintBMFont(const font: TBMFont; const text: string; const x, y: integer);
var
  a: integer;
  xOffset: integer;
begin
  xOffset := 0;

  for a:=1 to length(text) do
    inc(xOffset, PrintBMFontGlyph(font, text[a], x + xOffset, y));
end;


function PrintBMFontGlyphTint(const font: TBMFont; const ch: char; const x, y: integer; const tint: byte): integer;
var
  row, col: integer;
  g: PBMFontGlyph;
  srcY: integer;
  colour: byte;
begin
  g := @(font.glyphs[ord(ch)]);
  PrintBMFontGlyphTint := g^.xadvance;

  { Bounds check }
  if word(x + g^.width) >= VGAWidth then exit;
  if word(y + g^.height) >= VGAHeight then exit;

  for row := 0 to g^.height - 1 do begin
    srcY := g^.y + row;

    for col := 0 to g^.width - 1 do begin
      colour := font.bitmap.data^[srcY * font.bitmap.width + (g^.x + col)];

      if colour <> transparencyKey then
        AsmPSet(x + g^.xoffset + col, y + g^.yoffset + row, tint);
    end;
  end;
end;

procedure PrintBMFontTint(const font: TBMFont; const text: string; const x, y: integer; const tint: byte);
var
  a: word;
  { relative from x }
  xOffset: integer;
begin
  xOffset := 0;

  for a:=1 to length(text) do
    inc(xOffset, PrintBMFontGlyphTint(font, text[a], x + xOffset, y, tint));
end;


function MeasureBMFont(const font: TBMFont; const text: string): integer;
var
  a: word;
  ch: char;
  glyph: PBMFontGlyph;
  xOffset: integer;
begin
  xOffset := 0;

  for a:=1 to length(text) do begin
    ch := text[a];
    glyph := @(font.glyphs[ord(ch)]);
    inc(xOffset, glyph^.xadvance);
  end;

  MeasureBMFont := xOffset
end;

procedure SetTransparencyKey(const value: byte);
begin
  transparencyKey := value
end;

begin
  SetTransparencyKey($0D);
end.
