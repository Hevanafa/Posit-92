
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
  PianoInstrument: TInstrument;
  odeToJoy: TMelody;
  { TODO: More of your game state here }


procedure initInstruments;
begin
  with PianoInstrument do begin
    modulator.tremolo := false;
    modulator.vibrato := false;
    modulator.sustain := false;
    modulator.keyScale := false;
    modulator.multiplier := 1;
    modulator.totalLevel := 25; { octaves ? }
    modulator.attack := 15;
    modulator.decay := 4;
    modulator.sustainLevel := 6;
    modulator.release := 7;
    modulator.waveform := 0;
    
    carrier.tremolo := false;
    carrier.vibrato := false;
    carrier.sustain := false;
    carrier.keyScale := false;
    carrier.multiplier := 1;
    carrier.totalLevel := 0;
    carrier.attack := 15;
    carrier.decay := 4; 
    carrier.sustainLevel := 6;
    carrier.release := 7;
    carrier.waveform := 0;
    
    feedback := 6;
    algorithm := 0
  end;
  
  { NOTE: Add more of your instruments here }
end;

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
  lastSpace := false;
  
  AdLibDrv.init;

  { Required }
  initInstruments;
  AdLibDrv.loadInstrument(0, PianoInstrument);
  { Load more of your instruments here }

  with sfxCoin do begin
    noteCount := 3;
    instrument := 0;
    initNote(notes[0], NOTE_C, 5, 0.3, 127);
    initNote(notes[1], NOTE_E, 5, 0.3, 127);
    initNote(notes[2], NOTE_F, 5, 0.3, 127)
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
