{
  Base for test projects
  Part of Posit-92 game engine
}

program BaseTest;

uses
  CRT, DOS,
  P92Core, P92CONV, P92BMFON, P92GRAPH, P92TIME, P92VGA;

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

