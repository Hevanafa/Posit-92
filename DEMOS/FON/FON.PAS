{
  This unit file can't be compiled yet
	Requires the knowledge from FNT
}

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

var
  FONFile: file;
  NEHdr: TNEHeader;
  NEOffset, rsrcOffset: integer;

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

end.
