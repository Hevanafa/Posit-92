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
    bitmap: PBitmap;
  end;

procedure LoadBMFont(var font: PBMFont; const filename: string);
{ This also frees the bitmap handle }
procedure FreeBMFont(var font: PBMFont);

procedure PrintBMFont(const font: PBMFont; const text: string; x, y: integer; const transparencyKey: byte);
function MeasureBMFont(const font: PBMFont; const text: string): integer;


implementation

uses Conv, Logger, Panic, P92STR, P92VGA;

procedure ParseBMFontGlyph(var font: PBMFont; line: string);
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

  if (low(font^.glyphs) <= newGlyph.id) and
      (newGlyph.id <= high(font^.glyphs)) then
    font^.glyphs[newGlyph.id] := newGlyph;
end;

procedure LoadBMFont(var font: PBMFont; const filename: string);
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
  if font <> nil then
    writeLog('LoadBMFont: font isn''t nil!');

  WriteLog('LoadBMFont: Loading font from ' + filename);

  { getMem(font, sizeof(TBMFont)); }
  new(font);

  if font = nil then
    panicHalt('loadBMFont: Out of memory!');

  for b := low(font^.glyphs) to high(font^.glyphs) do
    fillchar(font^.glyphs[b], sizeof(TBMFontGlyph), 0);

  font^.bitmap := nil;

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
          font^.lineHeight := parseInt(kv[1]);
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

  loadBMP(font^.bitmap, bitmapPath);
  writeLog('Loaded ' + i32str(count) + ' glyphs');
end;


procedure FreeBMFont(var font: PBMFont);
var
  a, count: word;
begin
  if font = nil then exit;

  count:=0;
  {
  for a:=low(font^.glyphs) to high(font^.glyphs) do begin
    if font^.glyphs[a] <> nil then begin
      writeLog('Freeing glyph ' + i32str(a) + '...');

      dispose(font^.glyphs[a]);
      font^.glyphs[a] := nil;
      inc(count)
    end;
  end;
  }

  freeBMP(font^.bitmap);

  dispose(font);
  font := nil;

  writeLog('Freed ' + i32str(count) + ' glyphs')
end;


procedure PrintBMFont(const font: PBMFont; const text: string; x, y: integer; const transparencyKey: byte);
var
  a, row, col, dx, dy: integer;
  c: char;
  g: PBMFontGlyph;
  srcX, srcY: word;
  colour: byte;
begin
  if font = nil then exit;

  dx := x;
  for a:=1 to length(text) do begin
    c := text[a];
    g := @(font^.glyphs[ord(c)]);

    for row := 0 to g^.height - 1 do begin
      for col := 0 to g^.width - 1 do begin
        srcX := g^.x + col;
        srcY := g^.y + row;
        colour := font^.bitmap^.data[srcY * font^.bitmap^.width + srcX];

        if colour <> transparencyKey then
          pset(dx + g^.xoffset + col, y + g^.yoffset + row, colour);
      end;
    end;

    inc(dx, g^.xadvance)
  end;
end;


function MeasureBMFont(const font: PBMFont; const text: string): integer;
var
  a: integer;
  ch: char;
  glyph: PBMFontGlyph;
  result: integer;
begin
  if font = nil then begin
    MeasureBMFont := 0;
    exit
  end;

  result := 0;

  for a:=1 to length(text) do begin
    ch := text[a];
    if (low(font^.glyphs) <= ord(ch)) and (ord(ch) <= high(font^.glyphs)) then begin
      glyph := @(font^.glyphs[ord(ch)]);
      if glyph <> nil then
        inc(result, glyph^.xadvance);
    end;
  end;

  MeasureBMFont := result
end;

end.
