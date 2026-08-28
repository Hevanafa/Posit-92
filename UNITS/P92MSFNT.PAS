{
  Microsoft FNT (Windows Bitmap Font) utility unit
  Part of Posit-92 game engine

  Supports both monospaced and proportional Microsoft FNT
  files as used in Windows 95 and prior
}

unit P92MSFNT;

{$IFDEF FPC}{$MODE TP}{$ENDIF}
{$DEFINE DEBUG}

interface

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..0] of byte;

  TMSFontHeader = record
    version: word;
    size: longInt;  { size of file }
    copyright: array[0..59] of char; { copyright notice }

    typ,  { type field (originally dfType) }
    points, { point size }
    vertRes, { vertical resolution }
    horizRes, { horizontal resolution }
    ascent,
    internalLeading,
    externalLeading: word;

    italic,
    underline,
    strikeout: byte;

    weight: word;
    charset: byte; { character set }

    pixWidth,  { 0 for proportional fonts }
    pixHeight: word;
    pitchAndFamily: byte;

    avgWidth,
    maxWidth: word;

    firstChar,  { first character in the font }
    lastChar,  { last charcode in the font }
    defaultChar,  { the default glyph if there's no available glyph }
    breakChar: byte;

    widthBytes: word;  { Width of row in bytes (This is always even ??) }

    device,  { unused }
    face: longInt;  { face name, the absolute byte offset in the file }
    bitsPointer,
    bitsOffset: longInt; { where the bitmap data starts }
    reserved: byte;
  end;

  PMSFontGlyph = ^TMSFontGlyph;
  TMSFontGlyph = record
    width, height: byte;
    bitmapData: PByteArray;
  end;

  PMSFont = ^TMSFont;
  TMSFont = record
    header: TMSFontHeader;
    glyphs: array[0..255] of TMSFontGlyph;
  end;

procedure LoadMSFont(var font: TMSFont; const filename: string);
procedure FreeMSFont(var font: TMSFont);
procedure TestMSFontDisplay(const font: TMSFont; const ch: char);
procedure PrintMSFont(const font: TMSFont; const text: string; const x, y: integer; const colour: byte);
function MeasureMSFont(const font: TMSFont; const text: string): word;


implementation

uses P92LOG, P92CONV, P92MATHS, P92PANIC, P92VGA;

procedure DefaultMSFont(var font: TMSFont);
var
  len: word;
begin
  fillchar(font.header, sizeof(TMSFontHeader), 0);

  len := high(font.glyphs) - low(font.glyphs) + 1;
  fillchar(font.glyphs, sizeof(TMSFontGlyph) * len, 0);
end;

procedure LoadMSFont(var font: TMSFont; const filename: string);
var
  fntFile: file;
  c, charIndex: word;
  bitsWidth, charoffset: word;
  charHeight: word;
begin
  Assign(fntFile, filename);
  {$I-} Reset(fntFile, 1); {$I+}

  if IOResult <> 0 then
    panicHalt('LoadMSFont: Cannot open file ' + filename);

  DefaultMSFont(font);

  BlockRead(fntFile, font.header, sizeof(TMSFontHeader));
  charHeight := font.header.pixHeight;

{$IFDEF DEBUG}
  writeLog('--- Begin loadMSFont "' + filename + '"');
  writeLog('Copyright string: "' + font.header.copyright + '"');
  writeLog('Pixel height: ' + i32str(font.header.pixHeight));
{$ENDIF}

  for charIndex := 0 to high(font.glyphs) do
    FillChar(font.glyphs, SizeOf(TMSFontGlyph), 0);

  for charIndex := font.header.firstChar to font.header.lastChar do begin
  { for charIndex := font.header.firstChar to font^.header.firstChar + 9 do begin }
    Seek(fntFile,  sizeof(TMSFontHeader) + (charIndex - font.header.firstChar) * 4);
    BlockRead(fntFile, bitsWidth, 2);
    BlockRead(fntFile, charOffset, 2);

    writeLog(
      'Char ' + i32str(charIndex)
      + ': w=' + i32str(bitsWidth)
      + ', offset=' + i32str(charOffset));

    font.glyphs[charIndex].width := bitsWidth;
    font.glyphs[charIndex].height := charHeight;

    getmem(
      font.glyphs[charIndex].bitmapData,
      ceil(bitsWidth / 8) * charHeight);

    Seek(fntFile, charOffset);
    BlockRead(fntFile, font.glyphs[charIndex].bitmapData^, ceil(bitsWidth / 8) * charHeight);
  end;

  close(fntFile)
end;

{ This test can only be done in text mode }
procedure TestMSFontDisplay(const font: TMSFont; const ch: char);
var
  a, b: word;
  glyph: PMSFontGlyph;
  currentByte, bitMask: byte;
  offset: word;
begin
  glyph := @(font.glyphs[ord(ch)]);

  for b:=0 to glyph^.height - 1 do begin
    for a:=0 to glyph^.width - 1 do begin
      offset := b + glyph^.height * (a div 8);
      currentByte := glyph^.bitmapData^[offset];
      bitMask := 1 shl (7 - (a mod 8));

      if (currentByte and bitMask) <> 0 then
        write('#')
      else
        write('.');
    end;
    writeLn
  end;
end;

procedure FreeMSFont(var font: TMSFont);
var
  a: word;
begin
  for a:=0 to high(font.glyphs) do
    if Assigned(font.glyphs[a].bitmapData) then
      freemem(
        font.glyphs[a].bitmapData,
        ceil(font.glyphs[a].width / 8) * font.glyphs[a].height);

  DefaultMSFont(font)
end;


procedure PrintMSFont(
  const font: TMSFont;
  const text: string;
  const x, y: integer;
  const colour: byte);
var
  a, b, c, left: word;
  charcode, currentByte, bitMask: byte;
  glyph: PMSFontGlyph;
  offset: word;
begin
  left := 0;

  for c:=1 to length(text) do begin
    charcode := ord(text[c]);

    if font.glyphs[charcode].bitmapData = nil then
      glyph := @(font.glyphs[font.header.defaultChar])
    else
      glyph := @(font.glyphs[charcode]);

    for b:=0 to glyph^.height - 1 do
      for a:=0 to glyph^.width - 1 do begin
        offset := b + glyph^.height * (a div 8);
        currentByte := glyph^.bitmapData^[offset];
        bitMask := 1 shl (7 - (a mod 8));

        if (currentByte and bitMask) <> 0 then
          asmPset(x + left + a, y + b, colour);
      end;

    inc(left, font.glyphs[charcode].width)
  end;
end;

function MeasureMSFont(const font: TMSFont; const text: string): word;
var
  a, result, width: word;
  charcode: byte;
begin
  result := 0;

  for a:=1 to length(text) do begin
    charcode := ord(text[a]);

    if font.glyphs[charcode].bitmapData = nil then
      width := font.glyphs[font.header.defaultChar].width
    else
      width := font.glyphs[charcode].width;

    inc(result, width)
  end;
  
  MeasureMSFont := result
end;

end.
