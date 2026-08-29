{
  SoundBlaster test project
  Part of Posit-92 game engine
}

program SNDBLAST;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92CORE, P92CONV, P92BMFON, P92GRAPH, P92PANIC, P92TIME, P92VGA,
  P92SNDBL;

var
  fontP92Sans: TBMFont;


procedure OnPreload; far;
begin
  LoadBMFont(fontP92Sans, 'FONTS\P92SANS.TXT')
end;

procedure OnCleanup; far;
begin
  FreeBMFont(fontP92Sans)
end;

procedure OnReady; far;
begin
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

