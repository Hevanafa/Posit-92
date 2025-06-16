
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
    device, face: longInt;
    bitsPointer, bitsOffset: longInt;
    reserved: byte;
    flags: longInt;
    { deviceName, faceName: array[0..0] of char; }
  end;

var
  FONFile: File;
  NEHdr: TNEHeader;
  NEOffset, rsrcOffset: integer;
  version: word;
  fontDir: TFontDirEntry;

function CStrPas(const cstr: array of char): string;
var
  a: word;
  result: string;
begin
  a := 0;
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


begin
  parseFON('8514OEM.FON');
  readLn
end.
