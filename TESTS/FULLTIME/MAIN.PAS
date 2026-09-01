{
  Get full time (in seconds) since epoch
  Part of Posit-92 game engine
}

program BaseTest;

uses
  CRT, DOS,
  P92Core, P92CONV, P92BMFON, P92GRAPH, P92TIME, P92VGA;

const
  EpochJDN = 2440588;

var
  fontP92Sans: TBMFont;

function DateToJDN(const y, m, d: word): longint;
var
  a: longint;
begin
  a := (14 - m) div 12;

  DateToJDN :=
    (1461 * (y + 4800 - a)) div 4
    + (367 * (m + 12 * a - 2)) div 12
    - (3 * ((y + 4900 - a) div 100)) div 4
    + d - 32075
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
  w: word;
begin
  cls($70);

  { startTick := GetTimer; }

  { TODO: Your stress test here }

  { endTick := GetTimer; }

  w := MeasureBMFont(fontP92Sans, s);

  PrintBMFont(
    fontP92Sans,
    'Today''s date: ' + I32Str(DateToJDN()),
    (VGAWidth - w) shr 1, VGAHeight shr 1);

  {
  s := i32str(OpCount) + ' operations done in ' + F32Str(endTick - startTick) + 's';
  RectFill(
    0,
    VGAHeight - fontP92Sans.lineHeight * 2,
    MeasureBMFont(fontP92Sans, s),
    VGAHeight - fontP92Sans.lineHeight, $00);
  PrintBMFont(fontP92Sans, s, 0, VGAHeight - fontP92Sans.lineHeight * 2);
  }
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

