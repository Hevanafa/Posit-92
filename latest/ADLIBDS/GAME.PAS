{
  Minimal AdLib drum set demo
  Part of Posit-92 game framework
}

{$DEFINE DEBUG}

uses
  CRT, DOS,
  AdLib, Bitmap, Logger,
  Keyboard, Mouse, Timing, VGA;

const
  SC_ESC = $01;
  SC_SPACE = $39;
  SC_Q = $10;
  SC_W = $11;
  SC_E = $12;
  SC_R = $13;
  SC_T = $14;

var
  done: boolean;
  t: double;
  DosuEXE: array[0..1] of PBitmap;

  { TODO: Implement this }
  lastKeys: array[SC_Q..SC_T] of boolean;
  drumStates: array[0..4] of boolean;
  endTicks: array[0..4] of double;


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

  randomize;
  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
  
  AdLibDrv.init;
  AdLibDrv.setPercussive(true);
end;


procedure update;
var
  a: word;
  now: double;
begin
  updateDeltaTime;
  updateMouse;
  AdLibDrv.update;

  now := getTimer;

  { Your update code here }
  if lastKeys[SC_Q] <> isKeyDown(SC_Q) then begin
    lastKeys[SC_Q] := isKeyDown(SC_Q);

    { Bass drum }
    if lastKeys[SC_Q] then begin
      AdLibDrv.drumOn(BassDrumVoice, 52);
      drumStates[0] := true;
      endTicks[0] := now + 0.2;
    end;
  end;

  if lastKeys[SC_W] <> isKeyDown(SC_W) then begin
    lastKeys[SC_W] := isKeyDown(SC_W);

    { Snare drum }
    if lastKeys[SC_W] then begin
      AdLibDrv.drumOn(SnareDrumVoice, 40);
      drumStates[1] := true;
      endTicks[1] := now + 0.2;
    end;
  end;

  if lastKeys[SC_E] <> isKeyDown(SC_E) then begin
    lastKeys[SC_E] := isKeyDown(SC_E);

    { Tom-tom drum }
    if lastKeys[SC_E] then begin
      AdLibDrv.drumOn(TomTomVoice, 30);
      drumStates[2] := true;
      endTicks[2] := now + 0.2;
    end;
  end;

  if lastKeys[SC_R] <> isKeyDown(SC_R) then begin
    lastKeys[SC_R] := isKeyDown(SC_R);

    { Bass drum }
    if lastKeys[SC_R] then begin
      AdLibDrv.drumOn(CymbalVoice, 40);
      drumStates[3] := true;
      endTicks[3] := now + 0.2;
    end;
  end;

  if lastKeys[SC_T] <> isKeyDown(SC_T) then begin
    lastKeys[SC_T] := isKeyDown(SC_T);

    { Bass drum }
    if lastKeys[SC_T] then begin
      AdLibDrv.drumOn(HiHatVoice, 30);
      drumStates[4] := true;
      endTicks[4] := now + 0.2;
    end;
  end;

  if isKeyDown(SC_ESC) then done := true;
  
  { if lastSpace <> isKeyDown(SC_SPACE) then begin 
    lastSpace := isKeyDown(SC_SPACE); }

    { if lastSpace then
      AdLibDrv.playMelody(@sfxCoin, 0); }
    { if lastSpace then begin }
      { AdLibDrv.selectInstrument(0, 0); }
      { AdLibDrv.playMelodyNoInstrument(@odeToJoy, 0); }
    { end; }
  { end; }

  for a:=0 to high(drumStates) do begin
    if not drumStates[a] then continue;

    if now >= endTicks[a] then begin
      drumStates[a] := false;

      case a of
      0: AdLibDrv.drumOff(BassDrumVoice);
      1: AdLibDrv.drumOff(SnareDrumVoice);
      2: AdLibDrv.drumOff(TomTomVoice);
      3: AdLibDrv.drumOff(CymbalVoice);
      4: AdLibDrv.drumOff(HiHatVoice);
      end;
    end;
  end;
  
  t:=t+dt
end;


procedure draw;
var
  a: integer;
begin
  asmCls($7D);

  if (trunc(t * 1.5) and 1) = 0 then
    spr(dosuEXE[0], 148, 76, 13)
  else
    spr(dosuEXE[1], 148, 76, 13);

  print('Q - bass drum', 16, 16, 15);
  print('W - snare drum', 16, 24, 15);
  print('E - tom-tom', 16, 32, 15);
  print('R - cymbal', 16, 40, 15);
  print('T - hi-hat', 16, 48, 15);
  
  print('Esc - done', 16, 184, 15);

  AdLibDrv.drawDebug;

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
