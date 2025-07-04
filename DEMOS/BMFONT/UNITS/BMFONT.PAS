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
  destX, destY: integer;
  ch: char;
  g: PBMFontGlyph;
  srcX, srcY: word;
  colour: byte;

  width: word;
begin
  if font = nil then exit;
  if x >= 320 then exit;
  if y >= 200 then exit;

  destX := x; destY := y;
  for a:=1 to length(text) do begin
    ch := text[a];
    if (ord(ch) < low(font^.glyphs)) or (ord(ch) > high(font^.glyphs)) then continue;

    g := font^.glyphs[ord(ch)];
    if g = nil then continue;

asm
{ for (row = 0; row < g^.height; row++)}
@row_init:
  mov row, 0

@row_condition:
  les si, g
  { g^.height }
  mov ax, es:[si+8]
  cmp row, ax
  jg @row_end

@row_loop:

  { for (col = 0; col < g^.width; col++) }
  @col_init:
    mov col, 0

  @col_condition:
    les si, g
    { g^.width }
    mov ax, es:[si+6]
    cmp col, ax
    jg @col_end

  @col_loop:
    les si, g

    { srcX := g^.x + col; }
    mov ax, es:[si+2]
    add ax, col
    mov srcX, ax

    { srcY := g^.y + row; }
    mov ax, es:[si+4]
    add ax, row
    mov srcY, ax

    { get pixel from:
      font^.bitmap^.data[
        srcY * font^.bitmap^.width + srcX]
    }
    les si, font
    { Jump to font^.bitmap }
    add si, 642
    mov bx, es:[si]
    { font^.bitmap^.width }
    mov dx, es:[si + 2]

    { Assign ES:SI to TBitmap }
    mov es, dx
    mov si, bx

    mov ax, es:[si]
    mov width, ax

    { data offset: srcY * font^.bitmap^.width + srcX }
    mov bx, srcY
    mul bx
    add ax, srcX

    add ax, 4
    add si, ax
    mov al, es:[si]
    mov colour, al
    cmp al, transparencyKey
    je @col_next

    { Check bounds }
    les si, g

    mov ax, destY
    add si, 12
    add ax, es:[si]
    add ax, row
    cmp ax, 0
    jl @row_next
    cmp ax, 200
    jge @skip

    mov ax, destX
    sub si, 2
    add ax, es:[si]
    add ax, col
    cmp ax, 0
    jl @col_next
    cmp ax, 320
    jge @row_next

    { Calculate offset }
    { y + g^.yoffset + row }
    les si, g

    mov ax, destY
    add si, 12
    add ax, es:[si]
    add ax, row
    mov bx, 320
    mul bx

    { destX + g^.xoffset + col }
    add ax, destX
    sub si, 2
    add ax, es:[si]
    add ax, col
    mov bx, ax

    les di, surface
    add di, bx
    mov al, colour
    mov es:[di], al

  @col_next:
    inc col
    jmp @col_condition

  @col_end:

@row_next:
  inc row
  jmp @row_condition

@row_end:
@skip:
end;

    inc(destX, g^.xadvance)
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
