{
  SoundBlaster utility unit
  Part of Posit-92 game engine

  Rule on magic numbers:
  The constants must be placed closest to the context it's in

  The downside is that I'll have a lot of duplicate consts, but I won't have to
  scroll up and then jump back to the procedure (Alt+G in Lazarus)
}

unit P92SNDBL;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

const
  DSPBase = $220;  { SoundBlaster base port }
  SampleRate = 11025;  { 11025 Hz: common DOS game rate }


procedure Open;
procedure Close;

function GetIsIRQFired: boolean;
procedure HookSBIRQ;
procedure UnhookSBIRQ;

function BorrowDMABuffer: pointer;
function GetSinLUT(const idx: byte): byte;
function GetDMABufferPhys: longint;

function DSPReset: boolean;
procedure AllocDMABuffer(const size: word);
{ Programme the DMA for a transfer }
procedure ProgramDMA(const physAddr: longint; const transferLen: word);

procedure DSPWrite(const value: byte);
procedure DSPSetSampleRate(const rate: word);

procedure PlayToneBlocking(const freq, durationMs: word);
procedure PlayTone(const freq: word);


implementation

uses DOS, P92LOG, P92PANIC;

var
  isInitialised: boolean;
  SinTable: array[0..255] of byte;

  OldIRQ7: pointer;
  isIRQFired: boolean;

  DMABufferSize: word;
  DMAHalf: byte;

  { assigned in AllocDMABuffer }
  DMABufferRaw: pointer;
  DMABuffer: pointer;
  DMABufferPhys: longint;  { 20-bit physical address }

procedure Open;
begin
  if not DSPReset then
    PanicHalt('Couldn''t find the SoundBlaster driver');

  writelog('P92SNDBL.Open: BLASTER=' + GetEnv('BLASTER'));

  AllocDMABuffer(2048);
  DSPSetSampleRate(SampleRate);
  HookSBIRQ;

  isInitialised := true;
end;

procedure Close;
begin
  if not isInitialised then exit;

  UnhookSBIRQ;
  freemem(DMABufferRaw, DMABufferSize * 2);
end;

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


procedure SBInterrupt; interrupt;
var
  ack: byte;
  offset: word;
begin
  { TODO: Expand the magic numbers into consts -- DON'T add more comments }
  isIRQFired := true;

  offset := DMAHalf * (DMABufferSize div 2);

  { Fill this half with silence for now (128) }
  fillchar(
    mem[seg(DMABuffer^):ofs(DMABuffer^) + offset],
    DMABufferSize div 2, 128);

  DMAHalf := 1 - DMAHalf;

  { Acknowledge DSP: Just read the status port }
  ack := port[DSPBase + $0E];
  port[$20] := $20;
end;

function GetIsIRQFired:boolean;
begin
  GetIsIRQFired := isIRQFired;
end;

procedure HookSBIRQ;
const
  {
  This must match DOSBox config at this section:
  [sblaster]
  irq = (number)
  }
  SBIRQNumber = 7;

  {
  $0D is bit 5
  $0F is bit 7
  }
  SBIntVector = $08 + SBIRQNumber;
  SBIRQMask = 1 shl SBIRQNumber;

  PICMaskPort = $21;
begin
  isIRQFired := false;

  GetIntVec(SBIntVector, OldIRQ7);
  SetIntVec(SBIntVector, @SBInterrupt);

  { Unmask IRQ bit, 7th bit in this case }
  port[PICMaskPort] :=
    port[PICMaskPort] and (not SBIRQMask)
end;

procedure UnhookSBIRQ;
const
  { Must match DOSBox config }
  SBIRQNumber = 7;

  SBIntVector = $08 + SBIRQNumber;
  SBIRQMask = 1 shl SBIRQNumber;

  PICMaskPort = $21;
begin
  { Re-mask the IRQ }
  port[PICMaskPort] := port[PICMaskPort] or SBIRQMask;
  SetIntVec(SBIntVector, OldIRQ7)
end;

function DSPReset: boolean;
const
  { Obtained from Creative Labs' DSP documentation }
  DSPResetPort = $06;

  { Ports relative to DSPBase }

  DSPReadData = $0A;
  DSPWriteData = $0C;

  { The same as DSPWriteData, but the meaning differs depending on the context }
  DSPWriteStatus = $0C;
  DSPReadStatus = $0E;

  { Magic bits }

  DSPReady = $AA;
  DSPBitBusy = $80;  { Specifically bit 7: 0b1000_0000 }
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
const
  DMAPageBoundary = $10000;
  DMAPageMask = $FFFF0000;
var
  rawPhys, alignedPhys: longint;
begin
  DMABufferSize := size;
  getmem(DMABufferRaw, DMABufferSize * 2);

  rawPhys := longint(seg(DMABufferRaw^)) shl 4 + ofs(DMABufferRaw^);

  {
  The trick with `rawPhys and DMAPageMask` is to check whether
  the buffer start and end are in the same page, and if they don't,
  bump up to the next page boundary
  }

  if (rawPhys and DMAPageMask) <>
     ((rawPhys + DMABufferSize - 1) and DMAPageMask) then
    alignedPhys := (rawPhys and DMAPageMask) + DMAPageBoundary
  else
    alignedPhys := rawPhys;

  DMABufferPhys := alignedPhys;

  {
  The bit shifting here converts a 20-bit physical address
  back into a `segment:offset` pointer

  Real mode addresses work as `segment * 16 + offset`, so
  by dividing by 16 (`shr 4`) gives the `segment`, and
  the remainder gives the `offset`
  }

  DMABuffer := ptr(
    word(alignedPhys shr 4),
    word(alignedPhys and $F));
end;


procedure ProgramDMA(const physAddr: longint; const transferLen: word);
const
  DMAMaskPort = $0A;
  DMAModePort = $0B;
  DMAFlipFlop = $0C;
  DMAAddrPort = $02;
  DMACountPort = $03;
  DMAPagePort = $83;

  DMADisableCh1 = $05;
  DMAEnableCh1 = $01;

  DMAModeSingle = $49;
  DMAModeAutoInit = $59;
var
  offset: word;
  page: byte;
begin
  offset := word(physAddr and $FFFF);
  page := byte(physAddr shr 16);

  port[DMAMaskPort] := DMADisableCh1;

  { Writing 0 resets it so that the next write
    to Port[DMAAddrPort] is guaranteed to be the low byte }
  port[DMAFlipFlop] := 0;

  { read from memory, channel 1 }
  port[DMAModePort] := DMAModeSingle;
  { port[$0B] := $59; }  { $59 = auto-init }

  port[DMAAddrPort] := lo(offset);
  port[DMAAddrPort] := hi(offset);

  { Len - 1 because the DMA controller counts from 0 }
  port[DMACountPort] := lo(transferLen - 1);
  port[DMACountPort] := hi(transferLen - 1);

  port[DMAPagePort] := page;
  port[DMAMaskPort] := DMAEnableCh1;
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
const
  DSPCmdSingleCycle = $14;
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

  DSPWrite(DSPCmdSingleCycle);
  DSPWrite(lo(DMABufferSize - 1));
  DSPWrite(hi(DMABufferSize - 1));
end;


var
  a: word;
begin
  isInitialised := false;

  for a:=0 to 255 do
    SinTable[a] := 128 + round(127 * sin(a * 2 * pi / 256));
end.

