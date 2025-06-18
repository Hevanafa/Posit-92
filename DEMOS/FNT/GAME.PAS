{
  Minimum Microsoft bitmap font example
  Part of Posit-92 game framework
}

uses
  CRT, DOS,
  MSFNT, FPS, Logger, Timing, VGA;

var
  done: boolean;
  font: PMSFont;
  w: word;


procedure INIT;
begin
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;

  randomize;
  initFPSCounter;
  { loadMSFont(font, 'FONTS\8514OEM.FNT'); }
  loadMSFont(font, 'FONTS\VGASYS.FNT');
end;


procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  if keyPressed then if readKey = #27 then done := true;
end;


procedure draw;
begin
  asmCls($7D);

  printMSFont(font, 'Hello world with System font!', 160 - (w div 2), 120, 15);
  drawFPS;

  asmFlush
end;

begin
  {
  loadMSFont(testFont, '8514OEM.FNT');
  testMSFontDisplay(testFont, 'A');
  readLn;
  exit;
  }

  INIT;
  done := false;

  w := measureMSFont(font, 'Hello world with System font!');

  repeat
    update;
    draw
  until done;

  freeMSFont(font);

  freeBuffer;
  closeLogger;
  initTextMode
end.
