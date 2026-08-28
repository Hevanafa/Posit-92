{
  Minimum Microsoft bitmap font example
  Part of Posit-92 game framework
}

uses
  CRT, DOS,
  P92Core, MSFNT, P92KBD, P92VGA;

var
  fontSystem: TMSFont;

procedure OnPreload; far;
begin
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
end;


procedure Draw; far;
var
  s: string;
  w: word;
begin
  Cls($7D);

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

