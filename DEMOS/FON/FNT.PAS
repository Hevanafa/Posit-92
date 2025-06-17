
type
  TFNTHeader = record
    version: word;
    size: longInt;
    copyright: array[0..59] of char;

    typ, points, vertRes, horizRes,
    ascent, internalLeading, externalLeading: word;

    italic, underline, strikeout: byte;
    weight: word;
    charset: byte;
    pixWidth, pixHeight: word;  { only applicable to monospaced fonts }
    pitchAndFamily: byte;
    avgWidth, maxWidth: word;
    firstChar, lastChar, defaultChar, breakChar: byte;
    widthBytes: word;  { This is always even ?? }
    device, face: longInt;  { the absolute location in the file }
    bitsPointer, bitsOffset: longInt;
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
  writeLn('Total bitmap size: ', totalBitmapSize);

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

begin
  parseFNT('8514OEM.FNT');
  extractChar('8514OEM.FNT', 'A');

  readLn
end.
