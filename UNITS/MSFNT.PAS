{
  Microsoft FNT (Windows Bitmap Font) utility unit
  Part of Posit-92 game framework

  Supports both monospaced and proportional Microsoft FNT
  files as used in Windows 95 and prior
}

unit MSFNT;

interface

type
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
    bitmapData: array[0..0] of byte;
  end;

  PMSFont = ^TMSFont;
  TMSFont = record
    header: TMSFontHeader;
    glyphs: array[0..255] of PMSFontGlyph;
  end;

procedure loadFNT(var output: PMSFont; const filename: string);


implementation

procedure loadFNT(var output: PMSFont; const filename: string);
var
  fntFile: file;
begin
  assign(fntFile, filename);
  {$I-} reset(fntFile, 1); {$I+}
  if IOResult <> 0 then begin
    writeLn('loadFNT: Cannot open file ', filename);
    exit
  end;

  if output = nil then
    getMem(output, sizeof(TMSFont));

  blockRead(fntFile, output^.header, sizeof(TMSFontHeader));
  writeLn('Test read');
  writeLn('Copyright string: "', output^.header.copyright, '"');

  close(fntFile)
end;

end.