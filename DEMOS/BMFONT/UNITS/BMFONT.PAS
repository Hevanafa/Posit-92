unit BMFont;

interface

uses Bitmap;

type
  ui8 = byte;
  i8 = shortint;
  i16 = integer;
  ui16 = word;

  PBMFontGlyph = ^TBMFontGlyph;
  TBMFontGlyph = record
    id: ui16;
    x, y, width, height: ui16;  { 2, 4, 6, 8 }
    xoffset, yoffset: i16;  { 10, 12 }
    xadvance: i16; { 14 }
    { page, chnl: byte; }
  end;

  PBMFont = ^TBMFont;
  TBMFont = record
    glyphs: array[32..127] of PBMFontGlyph;
    filename: string;  { 384 }
    lineHeight: word;  { 640 }
    bitmap: PBitmap;  { 642 }
  end;

procedure loadBMFont(var output: PBMFont; const filename: string);
procedure freeBMFont(var font: PBMFont);

procedure printBMFont(const font: PBMFont; const text: string; x, y: integer; const transparencyKey: byte);
procedure pascalPrintBMFont(const font: PBMFont; const text: string; x, y: integer; const transparencyKey: byte);
procedure asmPrintBMFont(const font: PBMFont; const text: string; x, y: integer; const transparencyKey: byte);

function measureBMFont(const font: PBMFont; const text: string): integer;

implementation

uses Conv, Logger, Panic, Strings, VGA;

procedure loadBMFont(var output: PBMFont; const filename: string);
var
  a, b: integer;
  f: text;
  line: string;
  skipLine: boolean;
  pairs: array[0..11] of string;
  pairCount: word;
  kv: array[0..1] of string; { key-value pair }
  key, value: string;  { separated key-value pair }
  g: PBMFontGlyph;
  glyphID, parseResult, tempI32: integer;
begin
  if output <> nil then
    writeLog('loadBMFont: output isn''t nil!');

  getMem(output, sizeof(TBMFont));

  if output = nil then
    panicHalt('loadBMFont: Out of memory!');

  for a:=low(output^.glyphs) to high(output^.glyphs) do
    output^.glyphs[a] := nil;

  assign(f, filename);
  {$I-} reset(f); {$I+}
  if IOResult <> 0 then
    panicHalt('loadBMFont: Couldn''t find "' + filename + '"!');

  a := 0;
  skipLine := false;

  while not eof(f) do begin
    readln(f, line);
    skipLine := false;
    { writeLn('Line ', a, ': ', line); }

    while contains(line, '  ') do
      line := replaceAll(line, '  ', ' ');

    if startsWith(line, 'common') then begin
      pairCount := split(line, ' ', pairs);
      for b:=0 to pairCount-1 do begin
        split(pairs[b], '=', kv);
        if kv[0] = 'lineHeight' then
          output^.lineHeight := parseInt(kv[1]);
      end;
    end;

    if startsWith(line, 'page') then begin
      pairCount := split(line, ' ', pairs);
      for b:=0 to pairCount-1 do begin
        split(pairs[b], '=', kv);
        if kv[0] = 'file' then
          output^.filename := replaceAll(kv[1], '"', '');
      end;
    end;

    if startsWith(line, 'char') then begin
      { assign glyph info }
      pairCount := split(line, ' ', pairs);
      for b:=0 to pairCount-1 do begin
        split(pairs[b], '=', kv);
        key := kv[0]; value := kv[1];

        { case-of can't be used with strings in TP7 }
        if key = 'id' then begin
          glyphID := parseInt(value);

          if (low(output^.glyphs) <= glyphID) and (glyphID <= high(output^.glyphs)) then begin
            { writeLn('ID:', glyphID); }
            New(g);
            g^.id := glyphID;
            output^.glyphs[glyphID] := g
          end else begin
            { writeLn('Skipped glyph ', glyphID); }
            { when out of bounds }
            skipLine := true;
            break
          end;
        end
        else if key = 'x' then output^.glyphs[glyphID]^.x := parseInt(value)
        else if key = 'y' then output^.glyphs[glyphID]^.y := parseInt(value)
        else if key = 'width' then output^.glyphs[glyphID]^.width := parseInt(value)
        else if key = 'height' then output^.glyphs[glyphID]^.height := parseInt(value)
        else if key = 'xoffset' then output^.glyphs[glyphID]^.xoffset := parseInt(value)
        else if key = 'yoffset' then output^.glyphs[glyphID]^.yoffset := parseInt(value)
        else if key = 'xadvance' then output^.glyphs[glyphID]^.xadvance := parseInt(value);
      end;
    end;

    inc(a)
  end;
  close(f);

  loadBMP(output^.bitmap, output^.filename)
end;


procedure freeBMFont(var font: PBMFont);
var
  a, count: word;
begin
  if font = nil then exit;

  count:=0;
  for a:=low(font^.glyphs) to high(font^.glyphs) do begin
    if font^.glyphs[a] <> nil then begin
      dispose(font^.glyphs[a]);
      font^.glyphs[a] := nil;
      inc(count)
    end;
  end;
  freeBMP(font^.bitmap);
  font^.filename := '';
  font^.lineHeight := 0;

  writeLog('Freed ' + i32str(count) + ' glyphs')
end;


procedure printBMFont(const font: PBMFont; const text: string; x, y: integer; const transparencyKey: byte);
begin
  pascalPrintBMFont(font, text, x, y, transparencyKey)
end;


procedure pascalPrintBMFont(const font: PBMFont; const text: string; x, y: integer; const transparencyKey: byte);
var
  a, row, col, dx, dy: integer;
  ch: char;
  g: PBMFontGlyph;
  srcX, srcY: word;
  colour: byte;
begin
  if font = nil then exit;

  dx := x;
  for a:=1 to length(text) do begin
    ch := text[a];
    if (ord(ch) < low(font^.glyphs)) or (ord(ch) > high(font^.glyphs)) then continue;

    g := font^.glyphs[ord(ch)];
    if g = nil then continue;

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

procedure asmPrintBMFont(const font: PBMFont; const text: string; x, y: integer; const transparencyKey: byte);
var
  a, row, col: integer;
  dxi, dy: integer;
  ch: char;
  g: PBMFontGlyph;
  srcX, srcY: word;
  colour: byte;

  width: word;
begin
  if font = nil then exit;

  dxi := x;
  for a:=1 to length(text) do begin
    ch := text[a];
    if (ord(ch) < low(font^.glyphs)) or (ord(ch) > high(font^.glyphs)) then continue;

    g := font^.glyphs[ord(ch)];
    if g = nil then continue;

    for row := 0 to g^.height - 1 do begin
      for col := 0 to g^.width - 1 do begin
        srcX := g^.x + col;
        srcY := g^.y + row;
        {
        colour := font^.bitmap^.data[
          srcY * font^.bitmap^.width + srcX];
        }

asm
  les si, font
  { Jump to font^.bitmap }
  mov bx, es:[si + 642]
  { font^.bitmap^.width }
  mov dx, es:[si + 644]

  mov si, bx
  mov es, dx
  mov ax, es:[si]
  mov width, ax
end;
  
  writeLog('width is: ' + i32str(width));

asm
  { data offset: srcY * font^.bitmap^.width + srcX }
  mov bx, srcY
  mul width
  add bx, srcX
  mov ax, es:[si+bx]
  mov colour, ah

  mov al, colour
  cmp al, transparencyKey
  je @skip

  { TODO: Check bounds }

  { Calculate offset }
  { y + g^.yoffset + row }
  les si, g

  mov ax, y
  add si, 12
  add ax, es:[si]
  add ax, row
  mov bx, 320
  mul bx

  { dxi + g^.xoffset + col }
  add ax, dxi
  sub si, 2
  add ax, es:[si]
  add ax, col
  mov bx, ax

  les di, surface
  add di, bx
  mov al, colour
  mov es:[di], al

  @skip:
end;
      end;
    end;

    inc(dxi, g^.xadvance)
  end;
end;


function measureBMFont(const font: PBMFont; const text: string): integer;
var
  a: integer;
  ch: char;
  glyph: PBMFontGlyph;
  result: integer;
begin
  if font = nil then begin
    measureBMFont := 0;
    exit
  end;

  result := 0;

  for a:=1 to length(text) do begin
    ch := text[a];
    if (low(font^.glyphs) <= ord(ch)) and (ord(ch) <= high(font^.glyphs)) then begin
      glyph := font^.glyphs[ord(ch)];
      if glyph <> nil then
        inc(result, glyph^.xadvance);
    end;
  end;

  measureBMFont := result
end;

end.
