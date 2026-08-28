{
  Minimum Microsoft bitmap font example
  Part of Posit-92 game framework
}

uses
  CRT, DOS,
  P92Core, P92TEX, MSFNT, P92KBD, P92TIME, P92VGA;

var
  { Asset variables }
  texSpecimenP92: array[0..1] of TTexture;
  fontSystem: TMSFont;

  { Game state variables }
  t: double;

procedure OnPreload; far;
begin
  LoadTex(texSpecimenP92[0], 'IMG\SPP92_1.BMP');
  LoadTex(texSpecimenP92[1], 'IMG\SPP92_2.BMP');

  { The font file must be a font resource (FNT), not a font collection (FON) }
  { LoadMSFont(fontSystem, 'FONTS\8514OEM.FNT'); }
  LoadMSFont(fontSystem, 'FONTS\VGASYS.FNT');
end;

procedure OnCleanup; far;
begin
  FreeMSFont(fontSystem);
end;

procedure Update; far;
begin
  if isKeyDown(SC_ESCAPE) then SignalDone;

  t := t + DeltaTime
end;


procedure Draw; far;
var
  s: string;
  w: word;
begin
  Cls($4F);

  if frac(t * 1.5) >= 0.5 then
    Spr(texSpecimenP92[0], 148, 76)
  else
    Spr(texSpecimenP92[1], 148, 76);

  s := 'Hello world with System font!';
  w := MeasureMSFont(fontSystem, s);
  PrintMSFont(fontSystem, s, 160 - (w div 2), 120, 15);
end;

var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  @appConfig.OnPreload := @OnPreload;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

