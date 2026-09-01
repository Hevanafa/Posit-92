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

function GetFullTimer: double;
var
  y, m, d, dayOfWeek: word;
  dateSinceJDN, dateSinceEpoch: longint;
begin
  GetDate(y, m, d, dayOfWeek);
  dateSinceJDN := DateToJDN(y, m, d);
  dateSinceEpoch := dateSinceJDN - EpochJDN;

  GetFullTimer := dateSinceEpoch * 86400.0 + GetTimer
end;

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
  OpCount = 1;
var
  startTick, endTick: double;
  s: string;
  w: word;
  y, m, d, dayOfWeek: word;

  dateSinceJDN: longint;
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

