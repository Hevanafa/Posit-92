{
  Primitive drawing test project
  Part of Posit-92 game engine

  Tested on DOSBox-X with 20000 cycles/ms
  RandSeed is assigned in the OnReady procedure
}

program BaseTest;

uses
  CRT, DOS,
  P92CORE, P92CONV, P92BMFON, P92GRAPH, P92TIME, P92VGA;

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
  RandSeed := 255;
end;

procedure DrawOnce; far;
const
  OpCount = 1000;  { standard }
  { OpCount = 100; }  { minimal }
  { OpCount = 5000; }
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
    Inline asm: 0.0384s
    stosw: 0.0317s
  }
  {
  for a:=1 to OpCount do
    HLine(
      random(VGAWidth + 20) - 10,
      random(VGAWidth + 20) - 10,
      random(VGAHeight + 1), random(256));
  }

  {
    Base: 0.1143s
    AsmVLine2: 0.0568s
    After clipping: 0.1133s
    Inline asm: -0.0016s ??

    5000 ops:
    Base: 0.6585s
    Inline asm: 0.0993s
  }
  {
  for a:=1 to OpCount do
    VLine(
      random(VGAWidth + 20) - 10,
      random(VGAHeight + 20) - 10,
      random(VGAHeight + 20) - 10, random(256));
  }

  {
  for a:=1 to OpCount do
    Rect(
      random(VGAWidth + 20) - 10,
      random(VGAHeight + 20) - 10,
      random(VGAWidth + 20) - 10,
      random(VGAHeight + 20) - 10,
      random(256));
  }

  {
    Base version with HLine: 0.6220s
    Forward call to legacy AsmRectFill2: 0.6324s
    With clipping: 0.6195s
  }
  {
  for a:=1 to OpCount do
    RectFill(
      random(VGAWidth + 20) - 10,
      random(VGAHeight + 20) - 10,
      random(VGAWidth + 20) - 10,
      random(VGAHeight + 20) - 10,
      random(256));
  }

  {
    Original: 5.4095s
    Legacy AsmRectFillDither: 3.0664s
    After clipping: 9.8359s
    After row stride: 6.9543s
    After while-loop: 4.1920s
    After inline asm: 0.9902s
  }
  {
  for a:=1 to OpCount do
    RectFillDither(
      random(VGAWidth + 20) - 10,
      random(VGAHeight + 20) - 10,
      random(VGAWidth + 20) - 10,
      random(VGAHeight + 20) - 10,
      random(256));
  }

  {
    Original: 12.5950s
    First half with HLine: 6.9680s
    Second half with HLine: 0.8557s
    After longint precision fix: 0.9281s
  }
  for a:=1 to OpCount do
    TriFill(
      random(VGAWidth + 20) - 10,
      random(VGAHeight + 20) - 10,
      random(VGAWidth + 20) - 10,
      random(VGAHeight + 20) - 10,
      random(VGAWidth + 20) - 10,
      random(VGAHeight + 20) - 10,
      random(256));

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

