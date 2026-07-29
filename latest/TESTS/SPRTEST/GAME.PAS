{
  Sprite stress test

  All the benchmarks here are done with:
  DOSBox-X 2026.07.02 running fixed 20000 cycles/s
}
uses
  CRT, DOS,
  P92Core, Bitmap, BMPROT, Conv, Graphics, Logger, P92Mouse, Timing, P92VGA;

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


procedure Draw1000;
var
  a: word;
  s: string;
  startTime: double;
begin
  startTime := getTimer;

  { for a:=0 to 1000 do }
    { bounds check + UnsafeAsmPSet: 1.8706s
      AsmPSet: 1.6775s }
    { PascalSpr(dosuEXE[0], random(VGAWidth + 80) - 40, random(VGAHeight + 80) - 40, $0D); }

  { 1.8869s
    AsmPSet: 1.4280s, 1.4451s }
  { for a:=0 to 1000 do
    SprTint(dosuEXE[0], random(VGAWidth + 80) - 40, random(VGAHeight + 80) - 40, $0C); }

  for a:=0 to 1000 do
    Spr(dosuEXE[0], random(VGAWidth + 80) - 40, random(VGAHeight + 80) - 40);

  s := '1000 operations done in ' + f32str(getTimer - startTime) + 's';
  rectfill(0, 0, length(s) * 8 - 1, 8, 0);
  Print(s, 0, 0, 15);
end;

procedure Draw100;
var
  a: word;
  s: string;
  startTime: double;
begin
  startTime := GetTimer;

  {
    After each optimisation step: 0.8631s, 0.8244s, 0.7626s
    bounds check + UnsafeAsmPSet: 0.7505s
    AsmPset: 0.5550s
  }
  { for a:=0 to 100 do
    SprScaled(dosuEXE[0],
      random(DefaultVGAWidth) - 20,
      random(DefaultVGAHeight) - 20, 2); }

  { 0.6443s }
  for a:=0 to 100 do
    SprPro(
      DosuEXE[0],
      random(DefaultVGAWidth + 40) - 80,
      random(DefaultVGAHeight + 40) - 80,
      random(360));

  s := '100 operations done in ' + f32str(GetTimer - startTime) + 's';
  rectfill(0, 0, length(s) * 8 - 1, 8, 0);
  Print(s, 0, 0, 15);
end;

procedure DrawOnce; far;
var
  a, x, y: integer;
  s: string;
  startTime: double;
begin
  Cls($7D);

  Draw100;
  { Draw1000; }

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

