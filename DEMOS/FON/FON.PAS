{
  This unit file can't be compiled yet
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

  seek(fonFile, NEOffset);
  blockRead(fonFile, NEHeader, sizeOf(TNEHeader));

  writeLn('Magic: ', NEHeader.magic);
  writeLn('Resource table offset:', NEOffset + NEHeader.rsrctab);

  rsrcOffset := NEOffset + NEHeader.rsrctab;
  seek(fonFile, rsrcOffset);

  { Read the font dir entry }
  seek(fonFile, 340);
  blockRead(fonFile, fntHeader, sizeof(TFontDirEntry));

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

end.
