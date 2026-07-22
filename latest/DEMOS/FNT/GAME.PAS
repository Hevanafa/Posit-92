{
  Minimum Microsoft bitmap font example
  Part of Posit-92 game framework
}

uses
  CRT, DOS,
  P92Core, MSFNT, Keyboard, VGA;

var
  font: PMSFont;


procedure OnPreload; far;
begin
  { loadMSFont(font, 'FONTS\8514OEM.FNT'); }
  loadMSFont(font, 'FONTS\VGASYS.FNT');
end;

procedure OnCleanup; far;
begin
  freeMSFont(font);
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
  w := measureMSFont(font, s);
  printMSFont(font, s, 160 - (w div 2), 120, 15);
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

