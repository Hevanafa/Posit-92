{
  Sprite stress test

  All the benchmarks here are done with:
  DOSBox-X 2026.07.02 running fixed 20000 cycles/s
}
uses
  CRT, DOS,
  P92CORE, P92CONV, P92GRAPH, P92LOG, P92MOUSE, P92TEX, P92ROTO, P92TIME, P92VGA;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

var
  { Asset variables }
  texDosuEXE: array[0..1] of TTexture;

  { Game state variables }
  t: double;


procedure OnPreload; far;
begin
  LoadTex(texDosuEXE[0], 'IMG/DOSU_1.BMP');
  LoadTex(texDosuEXE[1], 'IMG/DOSU_2.BMP');
end;

procedure OnReady; far;
begin
  randseed := 255
end;

procedure OnCleanup; far;
begin
  FreeTex(texDosuEXE[0]);
  FreeTex(texDosuEXE[1]);
end;


procedure Draw1000;
var
  a: word;
  s: string;
  startTime: double;
begin
  startTime := getTimer;

  { Original: 1.4057s, 1.4158s
    With clipping: 0.8373s
    With inline assembly hot spot loop: 0.1787s, 0.1593s }
  for a:=0 to 1000 do
    Spr(texDosuEXE[0], random(VGAWidth + 80) - 40, random(VGAHeight + 80) - 40);

  { 1.8869s
    AsmPSet: 1.4280s, 1.4451s }
  { for a:=0 to 1000 do
    SprTint(texDosuEXE[0], random(VGAWidth + 80) - 40, random(VGAHeight + 80) - 40, random(256)); }

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
  { for a:=1 to 100 do
    SprScaled(texDosuEXE[0],
      random(DefaultVGAWidth) - 20,
      random(DefaultVGAHeight) - 20, 2); }

  { After each optimisation step: 0.6443s, 0.5956s, 0.5389s
    with AsmPSet: 0.4958s }
  { for a:=1 to 100 do
    SprRot(
      texDosuEXE[0],
      random(DefaultVGAWidth + 40) - 20,
      random(DefaultVGAHeight + 40) - 20,
      random(360)); }

  { 5.1285s, 5.0451s }
  { for a:=1 to 100 do
    SprScaleRot(
      texDosuEXE[0],
      random(DefaultVGAWidth + 40) - 20,
      random(DefaultVGAHeight + 40) - 20,
      2, 2,
      random(360)); }

  { 5.1915s, 5.2167s
    After `jae` optimisation on PSet: 5.0971s }
  {
  for a:=1 to 100 do
    SprScaleRotLUT(
      texDosuEXE[0],
      random(DefaultVGAWidth + 40) - 20,
      random(DefaultVGAHeight + 40) - 20,
      2, 2,
      random(36));
  }

  s := '100 operations done in ' + f32str(GetTimer - startTime) + 's';
  rectfill(0, 0, length(s) * 8 - 1, 8, 0);
  Print(s, 0, 0, 15);
end;

procedure DrawOnce; far;
const
  OpCount = 1000;
var
  s: string;
  startTime, endTime: double;
  a: word;
begin
  Cls($7D);

  startTime := GetTimer;

  {
    Original: 3.3217s
    With screen clipping: 2.8067s
    After row-level stride: 1.7502s
  }
  for a:=1 to OpCount do
    SprStretch(
      texDosuEXE[0],
      random(VGAWidth + 20) - 10,
      random(VGAHeight + 20) - 10,
      10 + random(30),
      10 + random(30));

  endTime := GetTimer - startTime;

  s := i32str(OpCount) + ' operations done in ' + f32str(endTime) + 's';
  rectfill(0, VGAHeight - 16, length(s) * 8, VGAHeight - 9, 0);
  Print(s, 0, VGAHeight - 16, 15);

  { Draw100; }
  { Draw1000; }
end;

var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.EnableKeyHandler := false;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.DrawOnce := @DrawOnce;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

