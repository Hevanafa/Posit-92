{$DEFINE DEBUG}

uses
  CRT, DOS,
  AdLib, Bitmap, Logger,  { AdLibPK }
  Keyboard, Mouse, Timing, VGA;

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
  snareOn: boolean;
  snareEndTick: double;
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


procedure setupOdeToJoy;
begin
  odeToJoy.noteCount := 16;
  odeToJoy.instrument := 0;

  initNote(odeToJoy.notes[0], NOTE_E, 4, 0.5, 120);
  initNote(odeToJoy.notes[1], NOTE_E, 4, 0.5, 120);
  initNote(odeToJoy.notes[2], NOTE_F, 4, 0.5, 120);
  initNote(odeToJoy.notes[3], NOTE_G, 4, 0.5, 120);
  
  initNote(odeToJoy.notes[4], NOTE_G, 4, 0.5, 120);
  initNote(odeToJoy.notes[5], NOTE_F, 4, 0.5, 120);
  initNote(odeToJoy.notes[6], NOTE_E, 4, 0.5, 120);
  initNote(odeToJoy.notes[7], NOTE_D, 4, 0.5, 120);

  initNote(odeToJoy.notes[8], NOTE_C, 4, 0.5, 120);
  initNote(odeToJoy.notes[9], NOTE_C, 4, 0.5, 120);
  initNote(odeToJoy.notes[10], NOTE_D, 4, 0.5, 120);
  initNote(odeToJoy.notes[11], NOTE_E, 4, 0.5, 120);

  initNote(odeToJoy.notes[12], NOTE_E, 4, 0.75, 120);
  initNote(odeToJoy.notes[13], NOTE_D, 4, 0.25, 120);
  initNote(odeToJoy.notes[14], NOTE_D, 4, 1.0, 120);
  initNote(odeToJoy.notes[15], NOTE_D, 4, 0.5, 80);
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
  {
  initInstruments;
  AdLibDrv.loadInstrument(0, @PianoInstrument);
  }
  AdLibDrv.setPercussive(true);
  setupOdeToJoy;

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
  now: double;
begin
  updateDeltaTime;
  updateMouse;
  AdLibDrv.update;

  { TODO: Your update code here }

  if isKeyDown(SC_ESC) then done := true;
  
  if lastSpace <> isKeyDown(SC_SPACE) then begin
    lastSpace := isKeyDown(SC_SPACE);

    { TODO: implement a full drumset }
    { if lastSpace then
      AdLibDrv.playMelody(@sfxCoin, 0); }
    if lastSpace then begin
      { AdLibDrv.selectInstrument(0, 0); }

      { AdLibDrv.playMelodyNoInstrument(@odeToJoy, 0); }

      { Bass drum }
      { AdLibDrv.drumOn(BassDrumVoice, 52); }

      { Snare drum }
      { AdLibDrv.drumOn(SnareDrumVoice, 40); }

      { Tom-tom }
      { AdLibDrv.drumOn(TomTomVoice, 30); }

      { Cymbal }
      AdLibDrv.drumOn(CymbalVoice, 40);

      { Hi-hat }
      { AdLibDrv.drumOn(HiHatVoice, 30); }

      snareOn := true;
      snareEndTick := getTimer + 0.2;
    end;
  end;

  now := getTimer;
  if snareOn then begin
    if now >= snareEndTick then begin
      snareOn := false;

      { AdLibDrv.drumOff(BassDrumVoice); }
      { AdLibDrv.drumOff(SnareDrumVoice); }
      { AdLibDrv.drumOff(TomTomVoice); }
      AdLibDrv.drumOff(CymbalVoice);
      { AdLibDrv.drumOff(HiHatVoice); }
    end;
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

  { print('Press Space to play chime', 160-100, 120, 15); }
  print('Press Space to play', 160-76, 120, 15);
  print('Ode to Joy', 160-40, 128, 15);

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
