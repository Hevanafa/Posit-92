{
  Base for test projects
  Part of Posit-92 game engine
}

program BaseTest;

uses
  CRT, DOS,
  P92Core, P92CONV, P92BMFON, P92GRAPH, P92TIME, P92VGA;

const
  DSPBase = $220;  { SoundBlaster base port }

var
  fontP92Sans: TBMFont;

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

end;

procedure DrawOnce; far;
const
  OpCount = 1;
var
  startTick, endTick: double;
  s: string;
begin
  cls($70);
  startTick := GetTimer;

  { TODO: Your stress test here }

  endTick := GetTimer;

  s := i32str(OpCount) + ' operations done in ' + F32Str(endTick - startTick) + 's';

  RectFill(
    0,
    VGAHeight - fontP92Sans.lineHeight * 2,
    MeasureBMFont(fontP92Sans, s),
    VGAHeight - fontP92Sans.lineHeight, $00);
  PrintBMFont(fontP92Sans, s, 0, VGAHeight - fontP92Sans.lineHeight * 2);
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

