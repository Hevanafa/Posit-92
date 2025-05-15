
uses
  CRT, DOS,
  Logger, Keyboard, Timing, VGA,
  Bitmap, Conv, FPS, BMFont;

const
  K_ESC = $01;
var
  done: boolean;
  t: double;
  lastB: boolean;
  font: TBMFont;


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

  { loadBMFont('COMMOD64.FNT', font); }
  loadBMFont('FR12.FNT', font);
end;


procedure update;
var
  a: integer;
begin
  updateDeltaTime;
  { updateMouse; }
  incrementFPS;

  { TODO: Your update code here }

  if isKeyDown(K_ESC) then done := true;

  t:=t+dt;
end;


procedure draw;
var
  a: integer;
  scoreStr: string;
begin
  cls($7D);

  { TODO: Your drawing code here }

  font.print('BMFont test', 160-48, 120, 15);

  { print('B - beep', 160-32, 130, 15); }

  { print('x:' + f32str(playerX) + ', y:' + f32str(playerY), 0, 0, 7); }
  scoreStr := f32str(t);
  font.print(scoreStr, 160, 8, 15);

  { drawMouse; }
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
