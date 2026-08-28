{
  Base for test projects
  Part of Posit-92 game engine
}

program BaseTest;

uses
  CRT, DOS,
  P92Core, P92CONV, P92BMFON, P92GRAPH, P92PANIC, P92TIME, P92VGA;

const
  DSPBase = $220;  { SoundBlaster base port }

var
  fontP92Sans: TBMFont;

  SinTable: array[0..255] of byte;

function DSPReset: boolean;
var
  a: word;
begin
  { TODO: Expand the magic numbers into consts }

  port[DSPBase + $6] := $01;  { trigger reset }
  for a:=1 to 100 do;
  port[DSPBase + $6] := $00;

  { Wait for DSP to report ready ($AA) }
  DSPReset := false;

  for a:=1 to high(word) do
    if (port[DSPBase + $E] and $80) <> 0 then
      if port[DSPBase + $A] = $AA then begin
        DSPReset := true;
        exit
      end;
end;

procedure DSPWrite(const value: byte);
begin
  { TODO: Expand the magic numbers into consts }

  while (port[DSPBase + $C] and $80) <> 0 do ; { poll until ready }
  port[DSPBase + $C] :=  value
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
end;

procedure DrawOnce; far;
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
  { TODO: expand the magic numbers into consts }
  for a:=0 to 7999 do begin
    DSPWrite($10);
    DSPWrite(SinTable[a and 255]);
  end;
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

