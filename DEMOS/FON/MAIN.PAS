
type
  TNEHeader = record
    magic, ver, rev, enttab,
    cbenttab: word;
    crc: longInt;

    flags, autodata, heap, stack: word;

    csip, sssp: longInt;

    cseg, cmod, cbnrestab, segtab,
    rsrctab, restab, modtab, imptab: word;

    nrestab: longInt;

    cmovent, align, cres: word;
    exetype, flagsOthers: byte;
  end;

  TFontDirEntry = record
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
  FONFile, FNTFile: File;
  NEHdr: TNEHeader;
  NEOffset, rsrcOffset: integer;
  version: word;
  fontDir: TFontDirEntry;
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

procedure parseFON(const filename: string);
begin
  writeLn('Attempting to parse ' + filename + '...');

  assign(fonFile, filename);
  {$I-} reset(fonFile, 1); {$I+}
  if IOResult <> 0 then begin
    writeLn('parseFON: Cannot open file ', filename);
    exit
  end;

  seek(fonFile, 60);
  blockRead(fonFile, NEOffset, 2);  { DOSHdr.e_lfanew, new EXE offset }
  writeLn('NEOffset: ', NEOffset);

  seek(fonFile, NEOffset);
  blockRead(fonFile, NEHdr, sizeOf(TNEHeader));

  writeLn('Magic: ', NEHdr.magic);
  writeLn('Resource table offset:', NEOffset + NEHdr.rsrctab);

  rsrcOffset := NEOffset + NEHdr.rsrctab;
  seek(fonFile, rsrcOffset);

  { Read the font dir entry }
  seek(fonFile, 340);
  blockRead(fonFile, fontDir, sizeof(TFontDirEntry));

  writeLn('Version: ', fontDir.version);
  writeLn('Width: ', fontDir.pixWidth, ', Height: ', fontDir.pixHeight);
  writeLn(fontDir.firstChar, '..', fontDir.lastChar);
  writeLn(chr(fontDir.firstChar) + ' - ' + chr(fontDir.lastChar));
  writeLn('Bytes per row: ', fontDir.widthBytes);
  writeLn('Face name offset: ', fontDir.face);

  writeLn('Copyright string: "', CStrPas(fontDir.copyright), '"');

  writeLn('Bitmap pointer: ', fontDir.bitsPointer);
  writeLn('Bitmap offset: ', fontDir.bitsOffset);


  { seek(fonFile, NEOffset + 36); }  { NEHdr.ne_rsrctab }
  { blockRead(fonFile, rsrcOffset, 2); }

  {
  inc(rsrcOffset, NEOffset);
  writeLn('rsrctab: ', rsrcOffset);
  }
  {
  seek(fonFile, rsrcOffset + 16);
  blockRead(fonFile, version, 2);
  writeLn('Version: ', version);
  }
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

  { Read the font dir entry }
  blockRead(fntFile, fontDir, sizeof(TFontDirEntry));

  seek(fntFile, fontDir.face);
  blockRead(fntFile, buffer, 8);
  faceName := CStrPas(buffer);

  writeLn('Version: ', fontDir.version);
  writeLn('Width: ', fontDir.pixWidth, ', Height: ', fontDir.pixHeight);
  writeLn(fontDir.firstChar, '..', fontDir.lastChar);
  writeLn(chr(fontDir.firstChar) + ' - ' + chr(fontDir.lastChar));
  writeLn('Bytes per row: ', fontDir.widthBytes);
  writeLn('Face name offset: ', fontDir.face);
  writeLn('Face name: "', faceName, '"');
  writeLn('Copyright string: "', CStrPas(fontDir.copyright), '"');

  writeLn('Bitmap pointer: ', fontDir.bitsPointer);
  writeLn('Bitmap offset: ', fontDir.bitsOffset);

  { Only applicable for monospaced fonts }
  charCount := fontDir.lastChar - fontDir.firstChar + 1;
  bytesPerChar := ((fontDir.pixWidth + 7) div 8) * fontDir.pixHeight;
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
  bytesPerRow: word;
  charOffset: longInt;
  bitmapData: array[0..255] of byte;
  currentByte, bitMask: byte;
  a, b, byteIndex: word;
begin
  assign(fntFile, filename);
  {$I-} reset(fntFile, 1); {$I+}
  if IOResult <> 0 then exit;

  bytesPerChar := ceil(fontDir.pixWidth / 8) * fontDir.pixHeight;
  writeLn('Bytes per char: ', bytesPerChar);

  charIndex := ord(ch);
  charOffset := fontDir.bitsOffset + (charIndex - fontDir.firstChar) * bytesPerChar;
  writeLn('Char offset: ', charOffset, ' (from ', fontDir.bitsOffset, ')');

  seek(fntFile, charOffset);
  blockRead(fntFile, bitmapData, bytesPerChar);

  { Display }
  byteIndex := 0;
  bytesPerRow := ceil(fontDir.pixWidth / 8);
  for b:=0 to fontDir.pixHeight - 1 do begin
    {
    byteIndex := b;
    write('+', byteIndex, ': ');
    }

    { for a:=0 to fontDir.pixWidth - 1 do begin }
    for a:=0 to 7 do begin
      currentByte := bitmapData[b + a div 8];

      {
      if (a mod 8) = 0 then begin
        currentByte := bitmapData[byteIndex];
        inc(byteIndex)
      end;
      }

      { bitMask := $80 shr (a mod 8); }
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
  parseFNT('8514OEM.FNT');
  extractChar('8514OEM.FNT', 'B');

  readLn
end.
