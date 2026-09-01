{
  Get full time (in seconds) since epoch
  Part of Posit-92 game engine
}

program FullTime;

uses
  CRT, DOS,
  P92Core, P92CONV, P92BMFON, P92GRAPH, P92TIME, P92VGA;

var
  fontP92Sans: TBMFont;

procedure PrintCentred(const text: string; const cx, y: integer);
var
  w: integer;
begin
  w := MeasureBMFont(fontP92Sans, text);

  PrintBMFont(
    fontP92Sans, text,
    cx - w shr 1, y)
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
  EpochJDN = 2440588;
var
  s: string;
  w: word;
  y, m, d, dayOfWeek: word;

  dateSinceJDN,
  dateSinceEpoch: longint;
begin
  cls($4F);

  GetDate(y, m, d, dayOfWeek);
  dateSinceJDN := DateToJDN(y, m, d);
  dateSinceEpoch := dateSinceJDN - EpochJDN;

  PrintCentred(
    'Today: ' + I32Str(d) + '-' + I32Str(m) + '-' + I32Str(y),
    VGAWidth shr 1, (VGAHeight shr 1) - fontP92Sans.lineHeight);

  PrintCentred(
    'Julian date number: ' + I32Str(dateSinceJDN),
    VGAWidth shr 1, VGAHeight shr 1);

  PrintCentred(
    'Days since epoch: ' + I32Str(dateSinceEpoch),
    VGAWidth shr 1, (VGAHeight shr 1) + fontP92Sans.lineHeight);

  PrintCentred(
    'Seconds since epoch: ' + F32Str(GetFullTimer),
    VGAWidth shr 1, (VGAHeight shr 1) + fontP92Sans.lineHeight * 2);
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

