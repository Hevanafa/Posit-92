
uses
  CRT, DOS,
  Logger, Keyboard, Timing, VGA,
  Bitmap, Conv, FPS, BMFont;

const
  K_ESC = $01;
var
  done: boolean;
  bootTime, t: double;
  font: PBMFont;

procedure INIT;
begin
  randomize;
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initKeyHandler;
  initFPSCounter;

  { loadBMFont(font, 'COMMOD64.FNT'); }
  loadBMFont(font, 'FR12.FNT');
  
  bootTime := getTimer;
end;


procedure update;
var
  a: integer;
begin
  updateDeltaTime;
  incrementFPS;

  if isKeyDown(K_ESC) then done := true;

  t := getTimer - bootTime;
end;


procedure draw;
var
  a, w: integer;
  s, scoreStr: string;
begin
  cls($7D);

  s := 'BMFont test';
  w := measureBMFont(font, s);
  { 291 FPS }
  pascalPrintBMFont(font, s, 160 - w div 2, 120, 13);
  { 315 FPS }
  { asmPrintBMFont(font, s, 160 - w div 2, 120, 13); }

  scoreStr := f32str(t);
  w := measureBMFont(font, scoreStr);
  pascalPrintBMFont(font, scoreStr, 160 - w div 2, 8, 13);
  { asmPrintBMFont(font, scoreStr, 160 - w div 2, 8, 13); }

  drawFPS;
  flush
end;


var
  a: integer;

begin
  INIT;
  done := false;

  repeat
    update;
    draw;
  until done;

  freeBMFont(font);

  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
