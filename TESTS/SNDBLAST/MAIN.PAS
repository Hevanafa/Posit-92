{
  Base for test projects
  Part of Posit-92 game engine
}

program BaseTest;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92Core, P92CONV, P92BMFON, P92GRAPH, P92PANIC, P92TIME, P92VGA;

const
  DSPBase = $220;  { SoundBlaster base port }
  SampleRate = 11025;  { 11025 Hz: common DOS game rate }

var
  fontP92Sans: TBMFont;

  SinTable: array[0..255] of byte;

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
  phaseIncrement := longint(256) * freq div SampleRate;
  phase := 0;

  for a:=0 to sampleCount - 1 do begin
    DSPWrite(DSPCmdDirectOut);
    DSPWrite(SinTable[phase and 255]);
    inc(phase, phaseIncrement)
  end;
end;

procedure OnPreload; far;
begin
  LoadBMFont(fontP92Sans, 'FONTS\P92SANS.TXT')
end;

procedure OnCleanup; far;
begin
  FreeBMFont(fontP92Sans)
end;

procedure OnReady; far;
var
  a: word;
begin
  for a:=0 to 255 do
    SinTable[a] := 128 + round(127 * sin(a * 2 * pi / 256));

  if not DSPReset then
    PanicHalt('Couldn''t find the SoundBlaster driver');

  DSPSetSampleRate(SampleRate);
end;

procedure DrawOnce; far;
const
  { Direct DAC output command }
  DSPCmdDirectOut = $10;
var
  s: string;
  a: word;
begin
  cls($4F);

  s := 'Playing the sine wave';

  RectFill(
    0,
    VGAHeight - fontP92Sans.lineHeight * 2,
    MeasureBMFont(fontP92Sans, s),
    VGAHeight - fontP92Sans.lineHeight, $00);

  PrintBMFont(fontP92Sans, s, 0, VGAHeight - fontP92Sans.lineHeight * 2);

  PresentMode13h;

  { Play the sine wave, blocking the main thread }
  { ~8000 samples, the duration depends on the CPU speed }
  {
  for a:=0 to 7999 do begin
    DSPWrite(DSPCmdDirectOut);
    DSPWrite(SinTable[a and 255]);
  end;
  }

  { C4 E4 G4 }
  PlayTone(262, 500);
  PlayTone(330, 500);
  PlayTone(392, 500);
end;

var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.LoadDefaultCursor := false;
  appConfig.EnableKeyHandler := false;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;

  { Use either Update + Draw, or DrawOnce }
  {
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  }

  @appConfig.DrawOnce := @DrawOnce;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

