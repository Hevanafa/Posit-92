
uses
  CRT, DOS,
  Logger, Keyboard, Timing, VGA,
  Bitmap, Conv, FPS, BMFont;

const
  K_ESC = $01;
var
  done: boolean;
  bootTime: double;
  t: double;
  lastB: boolean;
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

  { TODO: Your update code here }

  if isKeyDown(K_ESC) then done := true;

  t := getTimer - bootTime;
end;


procedure draw;
var
  a, w: integer;
  s, scoreStr: string;
begin
  asmCls($7D);

  { TODO: Your drawing code here }

  s := 'BMFont test';
  w := measureBMFont(font, s);
  printBMFont(font, s, 160 - w div 2, 120, 13);

  { print('B - beep', 160-32, 130, 15); }
  { print('x:' + f32str(playerX) + ', y:' + f32str(playerY), 0, 0, 7); }
  scoreStr := f32str(t);
  w := measureBMFont(font, scoreStr);
  { printBMFont(font, scoreStr, 160 - w div 2, 8, 13); }
  asmPrintBMFont(font, scoreStr, 160 - w div 2, 8, 13);

  { asmPrintBMFont(font, 'sizeof: ' + i32str(sizeof(PBMFontGlyph)), 0, 0, 13); }
  done := true;

  drawFPS;
  asmFlush
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
