{
  Base for test projects
  Part of Posit-92 game engine
}

program BaseTest;

uses
  CRT, DOS,
  P92Core, Conv, BMFont, Graphics, Timing, P92VGA;

var
  font: TBMFont;

procedure OnPreload; far;
begin
  LoadBMFont(font, 'FONTS\P92SANS.TXT')
end;

procedure OnCleanup; far;
begin
  FreeBMFont(font)
end;

procedure OnReady; far;
begin
  RandSeed := 255;
end;

procedure DrawOnce; far;
const
  OpCount = 1000;
var
  a: word;
  startTick, endTick: double;
  s: string;
begin
  cls($70);
  startTick := GetTimer;

  {
    Base: 0.2163s
    FillChar: 0.0395s
  }
  for a:=1 to OpCount do
    HLineBase(
      random(VGAWidth + 20) - 10,
      random(VGAWidth + 20) - 10,
      random(VGAHeight + 1), random(256));

  endTick := GetTimer;

  s := i32str(OpCount) + ' operations done in ' + F32Str(endTick - startTick) + 's';

  RectFill(
    0,
    VGAHeight - font.lineHeight * 2,
    MeasureBMFont(font, s),
    VGAHeight - font.lineHeight, $00);
  PrintBMFont(font, s, 0, VGAHeight - font.lineHeight * 2);
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

