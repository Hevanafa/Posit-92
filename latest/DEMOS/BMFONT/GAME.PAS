
uses
  CRT, DOS,
  P92Core, Logger,
  Keyboard, Mouse,
  Timing, VGA, Bitmap, Conv, FPS, BMFont;

var
  bootTime, t: double;
  font: PBMFont;

procedure OnPreload; far;
begin
  { loadBMFont(font, 'COMMOD64.FNT'); }
  { loadBMFont(font, 'FR12.FNT'); }
  loadBMFont(font, 'NOKIA.TXT')
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
  w := measureBMFont(font, s);
  PrintBMFont(font, s, 160 - w div 2, 120, 13);

  scoreStr := f32str(t);
  w := measureBMFont(font, scoreStr);
  PrintBMFont(font, scoreStr, 160 - w div 2, 8, 13);

  { Edge case tests }
  PrintBMFont(font, 'Left edge', -20, 10, 13);
  PrintBMFont(font, 'Top edge', 10, -8, 13);
  PrintBMFont(font, 'Right edge', 310, 10, 13);
  PrintBMFont(font, 'Bottom edge', 10, 192, 13);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

