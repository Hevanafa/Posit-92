{DEFINE MODEX}

uses
  CRT, DOS,
  Bitmap, Logger, Keyboard, Mouse, Timing, VGA, { ModeX, XBitmap, XMouse,} FPS;

const
  TARGET_FPS = 35;
  MAX_FRAME_SKIP = 5;
  SC_ESC = $01;
  SC_UP = $48;
  SC_DOWN = $50;
  SC_LEFT = $4B;
  SC_RIGHT = $4D;
var
  done: boolean;
  nextGameTick: double;
  loops: word;
  imgBill: PBitmap;
  x, y: single;
  
  { TODO: More of your game state here }


procedure INIT;
begin
  initLogger;
  { initModeX; }
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initKeyHandler;
  initMouse;
  initFPSCounter;

  randomize;
  {
  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
  }
  loadBMP(imgBill, 'IMG\BILL.BMP');
  
  x := 148;
  y := 76;
end;


procedure update;
begin
  updateDeltaTime;
  updateMouse;
  incrementFPS;

  { TODO: Your update code here }

  if isKeyDown(SC_ESC) then done := true;
  if isKeyDown(SC_LEFT) then x := x - dt * 60;
  if isKeyDown(SC_RIGHT) then x := x + dt * 60;
  if isKeyDown(SC_UP) then y := y - dt * 60;
  if isKeyDown(SC_DOWN) then y := y + dt * 60;
  

end;


procedure draw;
begin
  cls($7D);

  { TODO: Your drawing code here }

  spr(imgBill, trunc(x), trunc(y), 13);

  drawMouse;
  drawFPS;
  flush
  { flipPages }
end;


begin
  INIT;
  done := false;
  nextGameTick := getTimer;

  repeat
    loops := 0;
	
	while (getTimer > nextGameTick) and (loops < MAX_FRAME_SKIP) do begin
      update;
	  nextGameTick := nextGameTick + (1 / TARGET_FPS);
	  inc(loops)
	end;
	
    draw
  until done;

  { TODO: Your cleanup code here }
  freeBMP(imgBill);

  freeBuffer;
  resetMouse;
  resetKeyHandler;
  closeLogger;
  initTextMode
end.
