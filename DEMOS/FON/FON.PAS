{
  Requires the knowledge from FNT
}

type
  { TODO: Write what these fields are }
  TDOSHeader = record
    magic,
    cblp,
    cp,
    crlc,
    cparhdr,
    minalloc,
    maxalloc,
    ss, sp,
    csum,
    ip, cs,
    lfarlc,
    ovno: word;
    res: array[0..3] of word;
    oemid, oeminfo: word;
    res2: array[0..9] of word;
    lfanew: longInt;
  end;

  TNEHeader = record
    magic,
    ver,
    rev,
    enttab,
    cbenttab: word;

    crc: longInt;

    flags,
    autodata,
    heap,
    stack: word;

    csip,
    sssp: longInt;

    cseg,
    cmod,
    cbnrestab,
    segtab,
    rsrctab,
    restab,
    modtab,
    imptab: word;

    nrestab: longInt;

    cmovent,
    align,
    cres: word;

    exetype,
    flagsOthers: byte
  end;

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
  FONFile: file;
  DOSHeader: TDOSHeader;
  NEHeader: TNEHeader;
  NEOffset, rsrcOffset: integer;
  FNTHeader: TFNTHeader;

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

  { Read DOS Header }
  blockRead(fonFile, DOSHeader, sizeof(TDOSHeader));
  if DOSHeader.magic <> $5A4D then begin
    writeLn('parseFON: Not a valid DOS executable');
    close(fonFile);
    exit
  end;

  writeLn('Found NE header offset: ', DOSHeader.lfanew);

  NEOffset := DOSHeader.lfanew;
  seek(fonFile, NEOffset);
  blockRead(fonFile, NEHeader, sizeof(TNEHeader));

  { writeLn('Magic: ', NEHeader.magic); }
  writeLn('Resource table offset:', NEOffset + NEHeader.rsrctab);

  rsrcOffset := NEOffset + NEHeader.rsrctab;
  seek(fonFile, rsrcOffset);

  { TODO: Read the font dir entry }
  writeLn('--- Begin reading the FNT header ---');
  { seek(fonFile, 340); }
  seek(fonFile, 464);
  blockRead(fonFile, fntHeader, sizeof(TFNTHeader));

  writeLn('Version: ', fntHeader.version);
  writeLn('Width: ', fntHeader.pixWidth, ', Height: ', fntHeader.pixHeight);
  writeLn(fntHeader.firstChar, '..', fntHeader.lastChar);
  writeLn(chr(fntHeader.firstChar) + ' - ' + chr(fntHeader.lastChar));
  writeLn('Bytes per row: ', fntHeader.widthBytes);
  writeLn('Face name offset: ', fntHeader.face);

  writeLn('Copyright string: "', CStrPas(fntHeader.copyright), '"');

  writeLn('Bitmap pointer: ', fntHeader.bitsPointer);
  writeLn('Bitmap offset: ', fntHeader.bitsOffset);
end;

begin
  parseFON('8514OEM.FON');

  readLn
end.
