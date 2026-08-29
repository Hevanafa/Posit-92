unit P92SNDBL;

interface

const
  DSPBase = $220;  { SoundBlaster base port }
  SampleRate = 11025;  { 11025 Hz: common DOS game rate }

function BorrowDMABuffer: pointer;
function GetSinLUT(const idx: byte): byte;
function GetDMABufferPhys: longint;

function DSPReset: boolean;
procedure AllocDMABuffer(const size: word);
{ Programme the DMA for a transfer }
procedure ProgramDMA(const physAddr: longint; const size: word);

procedure DSPWrite(const value: byte);
procedure DSPSetSampleRate(const rate: word);

procedure PlayToneBlocking(const freq, durationMs: word);
procedure PlayTone(const freq: word);


implementation

var
  SinTable: array[0..255] of byte;

  DMABufferSize: word;

  DMABufferRaw: pointer;
  DMABuffer: pointer;
  DMABufferPhys: longint;  { 20-bit physical address }

function BorrowDMABuffer: pointer;
begin
  BorrowDMABuffer := DMABuffer
end;

function GetSinLUT(const idx: byte): byte;
begin
  GetSinLUT := SinTable[idx]
end;

function GetDMABufferPhys: longint;
begin
  GetDMABufferPhys := DMABufferPhys
end;


function DSPReset: boolean;
const
  { Obtained from Creative Labs' DSP documentation }
  DSPResetPort = $06;

  { The rest are also ports relative to DSPBase }

  DSPReadData = $0A;
  DSPWriteData = $0C;

  { The same as WriteData, but the meaning differs on the context }
  DSPWriteStatus = $0C;
  DSPReadStatus = $0E;

  { Magic bits }

  DSPReady = $AA;
  DSPBitBusy = $80;  { Specifically bit 7 }
var
  a: word;
begin
  port[DSPBase + DSPResetPort] := $01;  { trigger reset }
  for a:=1 to 100 do;
  port[DSPBase + DSPResetPort] := $00;

  { Wait for DSP to report ready ($AA) }
  DSPReset := false;

  for a:=1 to high(word) do
    if (port[DSPBase + DSPReadStatus] and DSPBitBusy) <> 0 then
      if port[DSPBase + DSPReadData] = DSPReady then begin
        DSPReset := true;
        exit
      end;
end;

procedure AllocDMABuffer(const size: word);
var
  rawPhys, alignedPhys: longint;
begin
  { TODO: Convert the magic numbers into consts }

  DMABufferSize := size;
  getmem(DMABufferRaw, DMABufferSize * 2);

  rawPhys := longint(seg(DMABufferRaw^)) shl 4 + ofs(DMABufferRaw^);

  if (rawPhys and $FFFF0000) <>
     ((rawPhys + DMABufferSize - 1) and $FFFF0000) then
    alignedPhys := (rawPhys and $FFFF0000) + $10000
  else
    alignedPhys := rawPhys;

  DMABufferPhys := alignedPhys;
  DMABuffer := ptr(word(alignedPhys shr 4), word(alignedPhys and $F));
end;

{ TODO: Review what does the "size" mean }
procedure ProgramDMA(const physAddr: longint; const size: word);
var
  offset: word;
  page: byte;
begin
  { TODO: Convert the magic numbers into consts }
  offset := word(physAddr and $FFFF);
  page := byte(physAddr shr 16);

  port[$0A] := $05;
  port[$0C] := 0;
  port[$0B] := $49;  { $49 = single cycle, read from memory, channel 1 }

  port[$02] := lo(offset);
  port[$02] := hi(offset);

  port[$03] := lo(size - 1);
  port[$03] := hi(size - 1);

  port[$83] := page;
  port[$0A] := $01;
end;

procedure DSPWrite(const value: byte);
const
  DSPWriteData = $0C;
  DSPWriteStatus = $0C;

  DSPBitBusy = $80;
begin
   { poll until ready }
  while (port[DSPBase + DSPWriteStatus] and DSPBitBusy) <> 0 do ;

  port[DSPBase + DSPWriteData] :=  value
end;


procedure DSPSetSampleRate(const rate: word);
const
  DSPCmdSetTimeConst = $40;
var
  timeConst: byte;
begin
  timeConst := byte(longint(256) - (1000000 div longint(rate)));

  DSPWrite(DSPCmdSetTimeConst);
  DSPWrite(timeConst)
end;

procedure PlayToneBlocking(const freq, durationMs: word);
const
  { Direct DAC output command }
  DSPCmdDirectOut = $10;
var
  sampleCount,
  phase,
  phaseIncrement: longint;
  a: longint;
begin
  sampleCount := longint(SampleRate) * durationMs div 1000;

  phaseIncrement := longint(256) * freq * 256 div SampleRate;
  phase := 0;

  for a:=0 to sampleCount - 1 do begin
    DSPWrite(DSPCmdDirectOut);
    DSPWrite(SinTable[(phase shr 8) and 255]);
    inc(phase, phaseIncrement)
  end;
end;

procedure PlayTone(const freq: word);
var
  phase, phaseIncrement: longint;
  a: word;
begin
  phaseIncrement := longint(256) * freq * 256 div SampleRate;
  phase := 0;

  for a:=0 to DMABufferSize - 1 do begin
    mem[Seg(DMABuffer^):Ofs(DMABuffer^) + a] :=
      SinTable[(phase shr 8) and 255];

    inc(phase, phaseIncrement)
  end;

  ProgramDMA(DMABufferPhys, DMABufferSize);

  DSPWrite($40);  { set time constant }
  DSPWrite(byte(longint(256) - (1000000 div SampleRate)));

  DSPWrite($14);
  DSPWrite(lo(DMABufferSize - 1));
  DSPWrite(hi(DMABufferSize - 1));
end;


var
  a: word;
begin
  for a:=0 to 255 do
    SinTable[a] := 128 + round(127 * sin(a * 2 * pi / 256));
end.

