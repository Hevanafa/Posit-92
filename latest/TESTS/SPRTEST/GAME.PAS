{
  Sprite stress test
  All the benchmarks here are done with 20000 cycles / s
}
uses
  CRT, DOS,
  P92Core, Bitmap, Conv, Graphics, Logger, P92Mouse, Timing, P92VGA;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

var
  { Asset variables }
  DosuEXE: array[0..1] of PBitmap;

  { Game state variables }
  t: double;


procedure OnPreload; far;
begin
  LoadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  LoadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;

procedure OnCleanup; far;
begin
  FreeBMP(dosuEXE[0]);
  FreeBMP(dosuEXE[1]);
end;


procedure DrawOnce; far;
var
  a, x, y: integer;
  startTime: double;
begin
  Cls($7D);
  startTime := getTimer;

  { 1.8692s, 1.8704s }
  for a:=0 to 1000 do
    PascalSpr(dosuEXE[0], random(300), random(180));

  { for a:=1 to 1000 do begin
    x := random(300);
    y := random(180); }

    { TODO: This only works once }
    { AsmSpr4(dosuEXE[0], x, y, 13); }
    { AsmSpr5(dosuEXE[0], x, y, 13); }
    { Print(i32str(a), x, y, 15); }
  { end; }

  { AsmSpr5(dosuEXE[0], 100, 50, 13);
  AsmSpr5(dosuEXE[0], 150, 50, 13); }

  {AsmSpr6(dosuEXE[0], 150, 50, 13);}

  { 0.6819s, 0.6826s }
  {
  for a:=1 to 1000 do begin
    x := random(300);
    y := random(180);

    AsmSpr7(dosuEXE[0], x, y, 13);
  end;
  }

  { Black rectangle behind the text below }
  rectfill(0, 0, 240, 8, 0);
  Print('1000 operations done in ' + f32str(getTimer - startTime) + 's', 0, 0, 15);
end;

var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.EnableKeyHandler := false;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.DrawOnce := @DrawOnce;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

