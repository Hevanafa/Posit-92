program Game;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  CRT, DOS,
  P92Core, P92LOG, Conv, BMFont, P92IMGUI, P92STR, P92TEX, Timing, P92VGA,
  P92KBD, P92Mouse;

var
  { Asset variables }
  P92SansFont: TBMFont;
  SpecimenP92: array[0..1] of TTexture;

  { Game state variables }
  t: double;
  clicks: integer;


procedure ReplaceColour(var tex: TTexture; const oldColour, newColour: byte);
var
  a, b: word;
  offset: word;
begin
  for b:=0 to tex.height - 1 do
    for a:=0 to tex.width - 1 do begin
      offset := b * tex.width + a;

      if tex.data^[offset] = oldColour then
        tex.data^[offset] := newColour;
    end;
end;


procedure OnPreload; far;
begin
  LoadBMFont(P92SansFont, 'FONTS\P92SANS.TXT');

  LoadTex(SpecimenP92[0], 'IMG/SPP92_1.BMP');
  LoadTex(SpecimenP92[1], 'IMG/SPP92_2.BMP');

  ReplaceColour(P92SansFont.texture, $0F, $00);
end;

procedure OnReady; far;
begin
  { Init game state variables here }
  clicks := 0;

  t := 0.0;
end;

procedure OnCleanup; far;
begin
  { Free all the resources here }
  FreeTex(SpecimenP92[0]);
  FreeTex(SpecimenP92[1]);
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

  PrintBMFont(P92SansFont, 'Test PrintBMFont', 100, 100);
  TextLabel('Hello world!', 160-48, 120);


  if Button('Clicks: ' + i32str(clicks), 10, 10, 64, 32) then
    inc(clicks);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.DefaultBMFont := @P92SansFont;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.
