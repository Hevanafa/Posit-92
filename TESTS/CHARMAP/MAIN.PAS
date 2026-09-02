{
  Base for test projects
  Part of Posit-92 game engine
}

program BaseTest;

uses
  CRT, DOS,
  P92Core, P92CONV, P92BMFON, P92GRAPH, P92TIME, P92VGA;

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

end;

procedure DrawOnce; far;
const
  HeadingColour = $0F;
  ColColour = $0A;
  CellColour = $0F;
var
  startTick, endTick: double;
  s: string;
  a, b: word;
begin
  cls($4F);

  startTick := GetTimer;

  print('Codepage ' + i32str(GetCodePage) + ' Map', 0, 0, HeadingColour);

  for a:=0 to 15 do begin
    { Table header }
    Print(i32str(a mod 10), 40 + 16 * a, 16, ColColour);

    { Table first column }
    Print(i32str(a * 16), 8, 32 + a * 8, ColColour);
  end;

  for b:=0 to 15 do
    for a:=0 to 15 do
      DrawCGAGlyph(char(b * 16 + a), 40 + 16 * a, 32 + b * 8, CellColour);

  endTick := GetTimer;

  s := 'Done in ' + F32Str(endTick - startTick) + 's';

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

