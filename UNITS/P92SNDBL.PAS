unit P92SNDBL;

interface

const
  DSPBase = $220;  { SoundBlaster base port }
  SampleRate = 11025;  { 11025 Hz: common DOS game rate }

function GetDMABufferPhys: longint;

procedure AllocDMABuffer(const size: word);
function DSPReset: boolean;

procedure DSPWrite(const value: byte);
procedure DSPSetSampleRate(const rate: word);
procedure PlayTone(const freq, durationMs: word);


implementation

var
  SinTable: array[0..255] of byte;

  DMABufferRaw: pointer;
  DMABuffer: pointer;
  DMABufferPhys: longint;  { 20-bit physical address }

function GetDMABufferPhys: longint;
begin
  GetDMABufferPhys := DMABufferPhys
end;

procedure AllocDMABuffer(const size: word);
var
  rawPhys, alignedPhys: longint;
begin
  { TODO: Convert the magic numbers into consts }
  getmem(DMABufferRaw, size * 2);

  rawPhys := longint(seg(DMABufferRaw^)) shl 4 + ofs(DMABufferRaw^);

  if (rawPhys and $FFFF0000) <>
     ((rawPhys + size - 1) and $FFFF0000) then
    alignedPhys := (rawPhys and $FFFF0000) + $10000
  else
    alignedPhys := rawPhys;

  DMABufferPhys := alignedPhys;
  DMABuffer := ptr(word(alignedPhys shr 4), word(alignedPhys and $F));
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

procedure PlayTone(const freq, durationMs: word);
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

var
  a: word;
begin
  for a:=0 to 255 do
    SinTable[a] := 128 + round(127 * sin(a * 2 * pi / 256));
end.

