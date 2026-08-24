program Game;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92Core, Logger, BMFont, P92STR, P92TEX, Timing, P92VGA,
  P92KBD, P92Mouse;

var
  { Asset variables }
  P92Sans: TBMFont;
  SpecimenP92: array[0..1] of TTexture;

  { Game state variables }
  t: double;


procedure PrintDefault(const text: string; const x, y: integer);
begin
  PrintBMFont(P92Sans, text, x, y)
end;

procedure OnPreload; far;
begin
  LoadBMFont(P92Sans, 'FONTS\P92SANS.TXT');
  LoadTex(SpecimenP92[0], 'IMG/SPP92_1.BMP');
  LoadTex(SpecimenP92[1], 'IMG/SPP92_2.BMP');
end;

procedure OnCleanup; far;
begin
  FreeBMFont(P92Sans);
  FreeTex(SpecimenP92[0]);
  FreeTex(SpecimenP92[1]);
end;

procedure OnReady; far;
begin
  { Init game state variables here }
  t := 0.0;
end;

procedure Update; far;
begin
  { Handle inputs here }
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  { Handle game state updates here }

  t := t + DeltaTime
end;

procedure Draw; far;
begin
  Cls($4F);

  if frac(t * 1.5) >= 0.5 then
    Spr(SpecimenP92[0], 148, 76)
  else
    Spr(SpecimenP92[1], 148, 76);

  PrintDefault('Hello world!', 160-48, 120);
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
