{
  Part of Light's Greed game
  By Hevanafa, 04-06-2025
}

uses
  CRT, DOS,
  Bitmap, Graphics, Logger, Keyboard, Mouse, Timing, VGA;

const
  SC_ESC = $01;
  SC_1 = $02;
  SC_2 = $03;
  SC_3 = $04;
var
  done: boolean;
  t: double;
  DosuEXE: array[0..1] of PBitmap;
  lights: array[0..3] of boolean;
  lastKeys: array[0..2] of boolean;
  allLightsOff: boolean;
  { TODO: More of your game state here }


procedure INIT;
begin
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initKeyHandler;
  initMouse;

  { TODO: Your init code here }

  randomize;
  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');

  allLightsOff := false;
  lights[0] := true;
  { lights[1] := true; }
  lights[2] := true;
  lights[3] := true;
end;

procedure updateAllLightsOff;
var
  a: word;
begin
  allLightsOff := true;
  for a:=0 to high(lights) do
    if lights[a] then begin
      allLightsOff := false;
      exit
    end;
end;


procedure update;
var
  a: word;
begin
  updateDeltaTime;
  updateMouse;

  for a:=0 to high(lastKeys) do begin
    if lastKeys[a] <> isKeyDown(a + SC_1) then begin
      lastKeys[a] := isKeyDown(a + SC_1);

      if lastKeys[a] then
        case a of
        0: begin
          { 1 2 }
          lights[0] := not lights[0];
          lights[1] := not lights[1];
        end;
        1: lights[2] := not lights[2];
        2: begin
          { 2 3 4 }
          lights[1] := not lights[1];
          lights[2] := not lights[2];
          lights[3] := not lights[3];
        end else
        end;

      updateAllLightsOff
    end;
  end;

  if isKeyDown(SC_ESC) then done := true;
  t:=t+dt
end;


procedure draw;
var
  a: word;
begin
  cls($7D);

  for a:=0 to high(lights) do
    if lights[a] then
      circfill(50 + a * 16, 40, 5, 15);

  if allLightsOff then
    print('Good job!', 50, 50, 15);

  if (trunc(t * 1.5) and 1) = 0 then
    asmSpr(dosuEXE[0], 148, 76, 13)
  else
    asmSpr(dosuEXE[1], 148, 76, 13);

  print('Hello world!', 160-48, 120, 15);
  drawMouse;
  flush
end;


begin
  INIT;
  done := false;

  repeat
    update;
    draw
  until done;

  { TODO: Your cleanup code here }
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);

  resetMouse;
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
