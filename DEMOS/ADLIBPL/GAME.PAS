
uses
  CRT, DOS,
  AdLib, Bitmap, Logger, Keyboard, Mouse, Timing, VGA;

const
  SC_ESC = $01;
  SC_SPACE = $39;
var
  done: boolean;
  t: double;
  DosuEXE: array[0..1] of PBitmap;
  sfxCoin: TMelody;
  lastSpace: boolean;
  odeToJoy: TMelody;
  { TODO: More of your game state here }


procedure INIT;
var
  tempNote: TNote;
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
  lastSpace := false;
  
  AdLibDrv.init;
  with sfxCoin do begin
    noteCount := 3;
    instrument := 0;
    initNote(notes[0], NOTE_C, 5, 0.1, 127);
    initNote(notes[1], NOTE_E, 5, 0.1, 127);
    initNote(notes[2], NOTE_C, 5, 0.1, 127)
  end;
end;


procedure update;
var
  a: integer;
begin
  updateDeltaTime;
  updateMouse;
  AdLibDrv.update;

  { TODO: Your update code here }

  if isKeyDown(SC_ESC) then done := true;
  
  if lastSpace <> isKeyDown(SC_SPACE) then begin
    lastSpace := isKeyDown(SC_SPACE);
    if lastSpace then
      AdLibDrv.playMelody(@sfxCoin, 0);
  end;
  
  t:=t+dt
end;


procedure draw;
var
  a: integer;
begin
  asmCls($7D);

  { TODO: Your drawing code here }

  if (trunc(t * 1.5) and 1) = 0 then
    spr(dosuEXE[0], 148, 76, 13)
  else
    spr(dosuEXE[1], 148, 76, 13);

  print('Press Space to play chime', 160-100, 120, 15);
  { debugAdLib; }
  drawMouse;
  asmFlush
end;


var
  a: integer;

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

  AdLibDrv.shutdown;
  resetMouse;
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
