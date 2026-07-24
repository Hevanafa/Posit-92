{
  Plasma demo
  17-05-2025
  Part of Posit-92 demos
  Author: Hevanafa
}

uses
  CRT, DOS,
  Logger, Keyboard, Mouse, Timing, VGA,
  Bitmap, FPS;

const
  K_ESC = $01;
var
  done: boolean;
  sinTable: array[0..255] of integer;
  startTime, t: double;
  { TODO: More of your game state here }

procedure buildSinTable;
var
  a: integer;
begin
  for a:=0 to 255 do
    sinTable[a] := round(128 + 127 * sin(a*2*pi/256))
end;


procedure INIT;
begin
  randomize;
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initKeyHandler;
  initMouse;

  initFPSCounter;

  { TODO: Your init code here }
  startTime := getTimer;
  buildSinTable;
end;


procedure update;
var
  a: integer;
begin
  updateDeltaTime;
  updateMouse;
  incrementFPS;

  { TODO: Your update code here }

  if isKeyDown(K_ESC) then done := true;
  t:=getTimer - startTime
end;


procedure draw;
const
  step = 2;
var
  a, b, c, d: integer;
  aIndex, bIndex: integer;
  ta, tb: integer;
  colour: byte;
begin
  ta := round(t) mod 256;
  tb := round(t * 2) mod 256;

  b := 0;
  while b <= 199 do begin
    bIndex := (b + tb) and 255;

    a := 0;
    while a <= 319 do begin
      aIndex := (a + ta) and 255;
      colour := sinTable[aIndex] + sinTable[bIndex];
      colour := 104 + (colour shr 2);

      { `surface` is pulled out from the implementation section }
      surface^[b*320 + a] := colour;
      surface^[b*320 + a+1] := colour;
      surface^[(b+1)*320 + a] := colour;
      surface^[(b+1)*320 + a+1] := colour;

      inc(a, step)
    end;
    inc(b, step)
  end;

  drawMouse;
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

  { TODO: Your cleanup code here }

  resetMouse;
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
