{
  Part of Posit-92 game framework
}

type
  TFNTHeader = record
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
    defaultChar,
    breakChar: byte;

    widthBytes: word;  { Width of row in bytes (This is always even ??) }

    device,  { unused }
    face: longInt;  { face name, the absolute byte offset in the file }
    bitsPointer,
    bitsOffset: longInt; { where the bitmap data starts }
    reserved: byte;
  end;

var
  FNTFile: File;
  version: word;
  FNTHeader: TFNTHeader;
  buffer: array[1..16] of char;
  faceName: string;

function CStrPas(const cstr: array of char): string;
var
  a: word;
  result: string;
begin
  a := low(cstr);
  result := '';

  while a < 255 do begin
    if cstr[a] = #0 then break;
    result := result + cstr[a];
    inc(a)
  end;

  CStrPas := result
end;


procedure parseFNT(const filename: string);
var
  charCount: word;
  bytesPerChar: longInt;
  totalBitmapSize: longInt;
begin
  writeLn('Attempting to parse ' + filename + '...');

  assign(fntFile, filename);
  {$I-} reset(fntFile, 1); {$I+}
  if IOResult <> 0 then begin
    writeLn('parseFNT: Cannot open file ', filename);
    exit
  end;

  { Read the font header entry }
  blockRead(fntFile, fntHeader, sizeof(TFNTHeader));

  seek(fntFile, fntHeader.face);
  blockRead(fntFile, buffer, 8);
  faceName := CStrPas(buffer);

  writeLn('Version: ', fntHeader.version);
  writeLn('Width: ', fntHeader.pixWidth, ', Height: ', fntHeader.pixHeight);
  writeLn(fntHeader.firstChar, '..', fntHeader.lastChar);
  writeLn(chr(fntHeader.firstChar) + ' - ' + chr(fntHeader.lastChar));
  writeLn('Bytes per row: ', fntHeader.widthBytes);
  writeLn('Face name offset: ', fntHeader.face);
  writeLn('Face name: "', faceName, '"');
  writeLn('Copyright string: "', CStrPas(fntHeader.copyright), '"');

  writeLn('Bitmap pointer: ', fntHeader.bitsPointer);
  writeLn('Bitmap offset: ', fntHeader.bitsOffset);

  { Only applicable for monospaced fonts }
  charCount := fntHeader.lastChar - fntHeader.firstChar + 1;
  bytesPerChar := ((fntHeader.pixWidth + 7) div 8) * fntHeader.pixHeight;
  totalBitmapSize := charCount * bytesPerChar;

  writeLn('Bytes per char: ', bytesPerChar);
  if totalBitmapSize > 0 then
    writeLn('Total bitmap size: ', totalBitmapSize, ' (monospaced)')
  else
    writeLn('Total bitmap size: ', totalBitmapSize, ' (proportional)');

  close(fntFile)
end;

function ceil(const value: double): integer;
begin
  if trunc(value) = value then
    ceil := trunc(value)
  else
    ceil := trunc(value + 1);
end;


procedure extractChar(const filename: string; const ch: char);
var
  charIndex: byte;
  bytesPerChar: word;
  charOffset: longInt;
  bitmapData: array[0..255] of byte;
  currentByte, bitMask: byte;
  a, b, byteIndex: word;
begin
  assign(fntFile, filename);
  {$I-} reset(fntFile, 1); {$I+}
  if IOResult <> 0 then exit;

  bytesPerChar := ceil(fntHeader.pixWidth / 8) * fntHeader.pixHeight;
  writeLn('Bytes per char: ', bytesPerChar);

  if bytesPerChar = 0 then begin
    writeLn('This is a proportional font (not monospaced)');
    exit
  end;

  charIndex := ord(ch);
  charOffset := fntHeader.bitsOffset + (charIndex - fntHeader.firstChar) * bytesPerChar;
  { writeLn('Char offset: ', charOffset, ' (from ', fntHeader.bitsOffset, ')'); }
  writeLn('Offsets: ', charOffset, ', ', charOffset + fntHeader.pixHeight);

  seek(fntFile, charOffset);
  blockRead(fntFile, bitmapData, bytesPerChar);

  { Display }
  byteIndex := 0;

  for b:=0 to fntHeader.pixHeight - 1 do begin
    for a:=0 to fntHeader.pixWidth - 1 do begin
      currentByte := bitmapData[
        b +
        fntHeader.pixHeight * (a div 8)];

      bitMask := 1 shl (7 - (a mod 8));
      if (currentByte and bitMask) <> 0 then
        write('#')
      else
        write('.');
    end;
    writeLn
  end;
  writeLn;

  close(fntFile)
end;

procedure extractProportionalChar(const filename: string; const ch: char);
var
  charIndex: byte;
  widthTable: array[0..255] of word;
  charWidth: word;
  charOffset: word;
  bitmapData: array[0..255] of byte;
  currentByte, bitMask: byte;
  a, b, byteIndex, skip: word;
begin
  assign(fntFile, filename);
  {$I-} reset(fntFile, 1); {$I+}
  if IOResult <> 0 then exit;

  if fntheader.pixWidth > 0 then begin
    writeLn('This is a monospaced font');
    exit
  end;

  for a:=0 to high(widthTable) do
    widthTable[a] := 0;


  { Read all char data }
  {
  seek(fntFile, sizeof(TFNTHeader));
  writeLn('Seeking to ', sizeof(TFNTHeader));
  for a:=fntHeader.firstChar to fntHeader.lastChar do begin
    blockRead(fntFile, widthTable[a], 2);
  }
    { blockRead(fntFile, skip, 2) } { this is supposed to be where the bitmap is }
  { end; }

  seek(fntFile, sizeof(TFNTHeader) + (ord(ch) - fntHeader.firstChar + 2) * 4);
  blockRead(fntFile, charWidth, 2);
  blockRead(fntFile, charOffset, 2);

  { Print the first 20 character widths }
  {
  for a:=fntHeader.firstChar to fntHeader.firstChar + 20 do
    write(widthTable[a], ', ');
  }

  charIndex := ord(ch);
  { charWidth := widthTable[charIndex]; }
  writeLn('Ch size: ', charWidth, 'x', fntHeader.pixHeight, ' (Offset:', charOffset, ')');

  seek(fntFile, charOffset);
  blockRead(fntFile, bitmapData, ceil(charWidth / 8) * fntHeader.pixHeight);

  { TODO: Display the character }
  for b:=0 to fntHeader.pixHeight-1 do begin
    for a:=0 to charWidth-1 do begin
      if a>=8 then break;

      currentByte := bitmapData[b + a div 8];
      bitMask := 1 shl (7 - a);
      if (currentByte and bitMask) <> 0 then
        write('#')
      else
        write('.');
    end;
    writeLn
  end;
  writeLn;

  close(fntFile)
end;


begin
{
  parseFNT('8514OEM.FNT');
  extractChar('8514OEM.FNT', 'A');
}
{
  parseFNT('CGA80WOA.FNT');
  extractChar('CGA80WOA.FNT', 'Z');
}
  parseFNT('HVGASYS.FNT');
  { extractChar('HVGASYS.FNT', 'Z'); }
  extractProportionalChar('HVGASYS.FNT', 'A');

  readLn
end.
