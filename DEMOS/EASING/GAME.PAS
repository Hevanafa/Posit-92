program Game;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92CORE, P92EASE, P92LOG, P92GRAPH, P92KBD, P92MOUSE, P92STR, P92TEX, P92TIME, P92VGA;

var
  { Asset variables }
  texSpecimenP92: array[0..1] of TTexture;

  { Game state variables }
  t: double;
  clickTick: double;

procedure OnPreload; far;
begin
  { Load assets here }
  LoadTex(texSpecimenP92[0], 'IMG/SPP92_1.BMP');
  LoadTex(texSpecimenP92[1], 'IMG/SPP92_2.BMP');
end;

procedure OnReady; far;
begin
  { Init game state variables here }
  t := 0.0;
  clickTick := 0.0;
end;

procedure OnCleanup; far;
begin
  { Free all the resources here }
  FreeTex(texSpecimenP92[0]);
  FreeTex(texSpecimenP92[1]);
end;

procedure Update; far;
begin
  { Handle inputs here }
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  { Handle game state updates here }

  t := t + DeltaTime
end;

procedure Draw; far;
var
  perc, lerpVal: double;
  x: integer;
begin
  Cls($4F);

  perc := GetPerc(clickTick, 3.0, t);
  lerpVal := trunc(LerpEased(100, 220, perc, EaseOutQuad));

  hline(100, 220, 80, $00);

  x := trunc(lerpVal - texSpecimenP92[0].width / 2);

  if frac(t * 1.5) >= 0.5 then
    Spr(texSpecimenP92[0], x, 64)
  else
    Spr(texSpecimenP92[1], x, 64);

  Print('Hello world!', 160-48, 120, 15);
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
