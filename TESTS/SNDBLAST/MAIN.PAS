{
  SoundBlaster test project
  Part of Posit-92 game engine
}

program SNDBLAST;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92CORE, P92CONV, P92BMFON, P92KBD, P92GRAPH, P92PANIC, P92TIME, P92VGA,
  P92SNDBL;

var
  lastSpacebar: boolean;
  fontP92Sans: TBMFont;

  frames: longint;


procedure OnPreload; far;
begin
  LoadBMFont(fontP92Sans, 'FONTS\P92SANS.TXT')
end;

procedure OnCleanup; far;
begin
  FreeBMFont(fontP92Sans);

  P92SNDBL.Close;
end;

procedure OnReady; far;
var
  a: word;
begin
  P92SNDBL.Open;

  frames := 0;
end;


procedure Update; far;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  if lastSpacebar <> IsKeyDown(SC_SPACE) then begin
    lastSpacebar := IsKeyDown(SC_SPACE);

    if lastSpacebar then
      P92SNDBL.PlayTone(262);
  end;

  inc(frames);
end;

procedure Draw; far;
var
  s: string;
begin
  cls($4F);

  s := 'Spacebar - Play tone C in sine wave';

  RectFill(
    0,
    VGAHeight - fontP92Sans.lineHeight * 2,
    MeasureBMFont(fontP92Sans, s),
    VGAHeight - fontP92Sans.lineHeight, $00);

  PrintBMFont(fontP92Sans, s, 0, VGAHeight - fontP92Sans.lineHeight * 2);

  PrintBMFont(fontP92Sans, 'Frame: ' + i32str(frames), 0, 30);

  PrintBMFont(fontP92Sans, 'isIRQFired: ' + BoolStr(GetIsIRQFired), 0, 50);
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

  PrintBMFont(fontP92Sans, 'DMABuf: ' + i32str(GetDMABufferPhys), 0, 20);

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
  PlayToneBlocking(262, 500);
  PlayToneBlocking(330, 500);
  PlayToneBlocking(392, 500);
end;

const
  UseDrawOnce = false;
var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.LoadDefaultCursor := false;
  appConfig.EnableKeyHandler := not UseDrawOnce;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;

  { Use either Update + Draw, or DrawOnce }
  if UseDrawOnce then
    @appConfig.DrawOnce := @DrawOnce
  else begin
    @appConfig.Update := @Update;
    @appConfig.Draw := @Draw;
  end;

  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

