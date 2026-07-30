{ Test games made with this using 386DX (4595 cycles/ms) CPU speed }

{$DEFINE DEBUG}
{DEFINE UNCAPPED}

uses
  CRT, DOS,
  Bitmap, Conv, FPS, Graphics, Logger, Maths,
  Keyboard, Strings, Timing,
  BMFont, Camera, NokiaVGA;

const
  TARGET_FPS = 30;

  SC_UP = $48;
  SC_DOWN = $50;
  SC_LEFT = $4B;
  SC_RIGHT = $4D;

  { Softkey keys }
  SC_RETURN = $1C;
  SC_Z = $2C;

  { C keys }
  SC_ESC = $01;
  SC_X = $2D;

var
  done: boolean;
  startTick, t: double;
  lastSoftKey: boolean;
  isSoftKey: boolean;

  nokiaFont, p8Font: PBMFont;
  imgRadio, imgSignal: PBitmap;
  imgPlayer, imgPlayerWalk: PBitmap;

  isMenu: boolean;
  radioCount: word;

  palette: array[0..1] of byte;
  x, y: integer;
  radioX, radioY: integer;
  { DosuEXE: array[0..1] of PBitmap; }
  { TODO: More of your game state here }


procedure clearVGAMem; assembler;
asm
  push es

  { Assign ES:DI to $A000:0000 }
  mov ax, $A000
  mov es, ax
  xor di, di

  xor ax, ax  { reset AX to 0 }
  mov cx, 32000
  cld
  rep stosw

  pop es
end;


procedure randomiseRadio;
begin
  radioX := 10 + random(64);
  radioY := 10 + random(28);
end;


procedure INIT;
begin
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;  { This uses NokiaVGA's buffer }
  initDeltaTime;
  initKeyHandler;

  initFPSCounter;
  initCamera;

  loadBMFont(nokiaFont, 'FONTS\NOKIA.TXT');
  loadBMFont(p8Font, 'FONTS\P8.TXT');

  loadBMP(imgRadio, 'IMG\RADIO.BMP');
  loadBMP(imgSignal, 'IMG\SIGNAL.BMP');
  loadBMP(imgPlayer, 'IMG\PSTAND.BMP');
  loadBMP(imgPlayerWalk, 'IMG\PWALK.BMP');

  randomize;
  palette[0] := 98;
  palette[1] := 8;

  {
  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
  }

  radioCount := 0;
  randomiseRadio;


  { TODO: There can be the art around the border}
  clearVGAMem;

  startTick := getTimer;
end;


procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  { TODO: Your update code here }

  if isKeyDown(SC_ESC) or isKeyDown(SC_X) then done := true;

  if isKeyDown(SC_UP) then dec(y);
  if isKeyDown(SC_DOWN) then inc(y);
  if isKeyDown(SC_LEFT) then dec(x);
  if isKeyDown(SC_RIGHT) then inc(x);
  isSoftKey := isKeyDown(SC_RETURN) or isKeyDown(SC_Z);

  if lastSoftKey <> isSoftKey then begin
    lastSoftKey := isSoftKey;

    if isSoftKey then
      isMenu := not isMenu;
  end;

  { TODO: Z or Enter - Soft key }
  { TODO: X or Escape - C button }

  cameraX := x - 40;  { 42 - 4 / 2 }
  cameraY := y - 21;  { 24 - 6 / 2 }

  if i32power(radioX - x, 2) + i32power(radioY - y, 2) <= 25 then begin
    inc(radioCount);
    randomiseRadio
  end;
  
  t := getTimer - startTick
end;

procedure drawFPS;
begin
  printBMFont(p8Font, 'fps:' + i32str(lastFPS), 55, 0, 13)
end;

procedure printP8(const txt: string; const x, y: integer);
begin
  printBMFont(p8Font, txt, x, y, 13)
end;

procedure printNokia(const txt: string; const x, y: integer);
begin
  printBMFont(nokiaFont, txt, x, y, 13)
end;


procedure draw;
var
  w: word;
  a: byte;
begin
  cls(palette[0]);

  if isMenu then begin
    printBMFont(nokiaFont, 'Game Menu', 0, 0, 13);

    nokiaFlushX2;
    exit
  end;

  { Radio }
  { pascalSpr(imgRadio, radioX, radioY, 13); }
  if trunc(t * 16) shr 1 and 1 = 1 then
    psetWithCamera(radioX, radioY, palette[1]);

  { Player }
  { pascalRect(x, y, x + 1, y + 1, palette[1]); }

  sprWithCamera(imgPlayer, x, y, 13);

  { HUD }
  pascalSpr(imgSignal, 0, 0, 13);

  w := measureBMFont(nokiaFont, 'Menu');
  printNokia('Menu', (84 - w) shr 1, 38);
  printNokia(padStart(i32str(radioCount), 4, '0'), 0, 6);

  if isSoftKey then
    printP8('Softkey is pressed!', 4, 4);

  drawFPS;

  { flush }
  nokiaFlushX2
end;


var
  now, nextGameTick: double;
begin
  INIT;

  nextGameTick := getTimer;

  x := 42; y := 24;

  isMenu := false;
  done := false;

{$IFDEF UNCAPPED}
  repeat
    update;
    draw
  until done;

{$ELSE}
  repeat
    now := getTimer;
    if now >= nextGameTick then begin
      nextGameTick := now + 1.0 / TARGET_FPS;
      update;
      draw
    end
  until done;
{$ENDIF}

  { TODO: Your cleanup code here }
  {
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);
  }
  freeBMP(imgRadio);
  freeBMP(imgSignal);
  freeBMP(imgPlayer);
  freeBMP(imgPlayerWalk);

  freeBMFont(nokiaFont);
  freeBMFont(p8Font);

  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
