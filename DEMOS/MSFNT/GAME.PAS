{
  Minimum Microsoft bitmap font example
  Part of Posit-92 game framework
}

uses
  CRT, DOS,
  P92Core, MSFNT, P92KBD, P92VGA;

var
  font: TMSFont;


procedure OnPreload; far;
begin
  { LoadMSFont(font, 'FONTS\8514OEM.FNT'); }
  LoadMSFont(font, 'FONTS\VGASYS.FNT');
end;

procedure OnCleanup; far;
begin
  FreeMSFont(font);
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
  w := MeasureMSFont(font, s);
  PrintMSFont(font, s, 160 - (w div 2), 120, 15);
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

