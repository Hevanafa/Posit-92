
uses
  CRT, DOS,
  P92Core, Logger, P92KBD, P92Mouse, Graphics, Timing, P92VGA, Bitmap, Conv, FPS, BMFont;

var
  bootTime, t: double;
  font: TBMFont;

procedure OnPreload; far;
begin
  { loadBMFont(font, 'COMMOD64.FNT'); }
  { loadBMFont(font, 'FR12.FNT'); }
  LoadBMFont(font, 'NOKIA.TXT')
end;

procedure OnReady; far;
begin
  bootTime := getTimer
end;

procedure OnCleanup; far;
begin
  freeBMFont(font)
end;

procedure Update; far;
var
  a: integer;
begin
  if isKeyDown(SC_ESCAPE) then SignalDone;

  t := getTimer - bootTime
end;


procedure Draw; far;
var
  a, w: integer;
  s, scoreStr: string;
begin
  cls($7D);

  s := 'BMFont test';
  w := MeasureBMFont(font, s);
  PrintBMFont(font, s, 160 - w div 2, 120);

  scoreStr := f32str(t);
  w := MeasureBMFont(font, scoreStr);
  PrintBMFont(font, scoreStr, 160 - w div 2, 8);

  { Edge case tests }
  PrintBMFont(font, 'Left edge', -20, 10);
  PrintBMFont(font, 'Top edge', 10, -8);
  PrintBMFont(font, 'Right edge', 310, 10);
  PrintBMFont(font, 'Bottom edge', 10, 192);
end;

procedure DrawOnce; far;
var
  startTick: double;
  a: Integer;
  s: string;
begin
  cls($00);
  startTick := GetTimer;

  for a:=1 to 1000 do
    PrintBMFont(font, 'Hello world!', random(VGAWidth) - 20, random(VGAHeight) - 20);

  s := '1000 operations done in ' + F32Str(GetTimer - startTick) + 's';

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

  appConfig.EnableKeyHandler := false;
  appConfig.LoadDefaultCursor := false;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  { @appConfig.Update := @Update;
  @appConfig.Draw := @Draw; }
  @appConfig.DrawOnce := @DrawOnce;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

