{
  BMFont test programme
  Part of Posit-92 game engine

  The tests here use DOSBox-X with fixed 20000 cycles/s, so that
  the tests have the same amount of cycles
}

uses
  CRT, DOS,
  P92Core, P92BMFON, P92LOG, P92KBD, P92Mouse, P92GRAPH, P92TIME, P92VGA, P92TEX, P92CONV, P92FPS;

var
  bootTime, t: double;
  fontP92Sans: TBMFont;

procedure OnPreload; far;
begin
  { loadBMFont(fontP92Sans, 'COMMOD64.FNT'); }
  { loadBMFont(fontP92Sans, 'FR12.FNT'); }
  { LoadBMFont(fontP92Sans, 'NOKIA.TXT') }
  LoadBMFont(fontP92Sans, 'FONTS\P92SANS.TXT');
end;

procedure OnReady; far;
begin
  RandSeed := 255;

  bootTime := getTimer
end;

procedure OnCleanup; far;
begin
  freeBMFont(fontP92Sans)
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
  w := MeasureBMFont(fontP92Sans, s);
  PrintBMFont(fontP92Sans, s, 160 - w div 2, 120);

  scoreStr := f32str(t);
  w := MeasureBMFont(fontP92Sans, scoreStr);
  PrintBMFont(fontP92Sans, scoreStr, 160 - w div 2, 8);

  { Edge case tests }
  PrintBMFont(fontP92Sans, 'Left edge', -20, 10);
  PrintBMFont(fontP92Sans, 'Top edge', 10, -8);
  PrintBMFont(fontP92Sans, 'Right edge', 310, 10);
  PrintBMFont(fontP92Sans, 'Bottom edge', 10, 192);
end;

procedure DrawOnce; far;
const
  OpCount = 100;
var
  startTick, endTick: double;
  a: Integer;
  s: string;
begin
  cls($00);
  startTick := GetTimer;

  {
    1000 ops
    Original: 1.4003s, 1.4025s
    After row-level opt: 1.0842s, 1.0609s
    After Word bounds check: 0.9086s, 0.9418s
    With AsmPSet call: 0.7352s, 0.7405s
    With early exits: 0.7821s, 0.7369s, 0.6990s, 0.7139s
    With precomputed offset: 0.7583s, 0.7725s
    Inner loop `col` with inline assembly: 0.3496s, 0.3557s

    01-09-2026:
    PrintBMFontGlyphFast: 0.5205s
    PrintBMFontGlyphSprRegion: 0.9841s

    100 ops
    PrintBMFontGlyphSprRegion: 0.1385s
  }
  for a:=1 to OpCount do
    PrintBMFont(fontP92Sans, 'Hello world!', random(VGAWidth) - 20, random(VGAHeight) - 20);

  {
    Original: 0.9003s
    After row-level opt: 0.7982s

    01-09-2026
    Original: 1.3769s
  }
  {
  for a:=1 to 1000 do
    PrintBMFontTint(fontP92Sans, 'Hello world!', random(VGAWidth) - 20, random(VGAHeight) - 20, random(248));
  }

  endTick := GetTimer - startTick;

  s := I32Str(OpCount) + ' operations done in ' + F32Str(endTick) + 's';

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
  { appConfig.WaitMode := P92WaitUncapped; }
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

