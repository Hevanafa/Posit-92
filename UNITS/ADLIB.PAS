{
  AdLib FM synthesiser interface utility unit
  Part of Posit-92 game framework
}

unit AdLib;

interface

const
  { Internal chip values for notes }
  NOTE_C  = $157;
  NOTE_CS = $16B;
  NOTE_D  = $181;
  NOTE_DS = $198;
  NOTE_E  = $1B0;
  
  NOTE_F  = $1CA;
  NOTE_FS = $1E5;
  NOTE_G = $202;
  NOTE_GS = $220;
  NOTE_A = $241;
  NOTE_AS = $263;
  NOTE_B = $287;

  
type
  TNote = record
    freq: word;
    octave: byte;
    duration: double;  { in seconds }
    velocity: byte  { 0..127 }
  end;

  PMelody = ^TMelody;
  TMelody = record
    notes: array[0..15] of TNote;
    noteCount: byte;
    instrument: byte;
  end;

  TInstrParams = record
    tremolo: boolean;
    vibrato: boolean;
    sustain: boolean;
    keyScale: boolean;
    multiplier, totalLevel, sustainLevel: byte;
    attack, decay, release, waveform: byte;
  end;
  PInstrument = ^TInstrument;
  TInstrument = record
    modulator: TInstrParams;
    carrier: TInstrParams;
    feedback: byte;
    algorithm: byte;  { 0 = FM, 1 = Additive }
  end;

  PAdLibDriver = ^TAdLibDriver;
  TAdLibDriver = object
    function getIsInitialised: boolean;
    procedure init;
    procedure update;
    procedure shutdown;
    procedure setPercussive(const value: boolean);    

    procedure loadInstrument(const slot: byte; const instr: PInstrument);
    procedure selectInstrument(const voice, slot: byte);
    procedure setMelodicInstruments;
    procedure setRhythmInstruments;

    { Playback }
    procedure playNote(const voice: byte; const freq: word; const octave, velocity: byte);
    procedure stopVoice(const voice: byte);
    
    procedure playMelody(const melody: PMelody; const voice: byte);
    procedure stopAllVoices;
  end;

var
  AdLibDrv: TAdLibDriver;

procedure initNote(
  var note: TNote;
  const freq: word;
  const octave: byte;
  const duration: double;
  const velocity: byte);

procedure AdLibWrite(const reg, value: byte);


implementation

uses CRT, Logger, Panic, Timing;

type
  TVoiceState = record
    active: boolean;
    melody: PMelody;
    noteIndex: byte;
    noteEndTick: double; { in seconds }
    instrument: byte;
    volume: byte; { 0..127 }
  end;

const
  AddressPort = $388;  { Address / status port }
  StatusPort = $388;
  DataPort = $389;  { Data port }
  
  MAX_VOICES = 9; { indices 0..8 }
  MAX_INSTRUMENTS = 16; { indices 0..15 }

var
  isInitialised: boolean;
  isPercussive: boolean;
  voices: array[0..MAX_VOICES-1] of TVoiceState;
  instruments: array[0..MAX_INSTRUMENTS-1] of PInstrument;


procedure AdLibWrite(const reg, value: byte);
var
  a: byte;
begin
  Port[AddressPort] := reg;
  for a:=1 to 3 do;  { simulated delay }
  Port[DataPort] := value;
  for a:=1 to 12 do;  { simulated delay }
end;

{
  freq uses NOTE_ prefix
  octave is the same as "block" in AdLib
  duration is in seconds
  velocity: 0..127
}
procedure initNote(
  var note: TNote;
  const freq: word;
  const octave: byte;
  const duration: double;
  const velocity: byte);
begin
  note.freq := freq;
  note.octave := octave;
  note.duration := duration;
  note.velocity := velocity;
end;

function getModulatorOffset(const voice: byte): byte;
begin
  case voice of
  0: getModulatorOffset := $00;
  1: getModulatorOffset := $01;
  2: getModulatorOffset := $02;

  3: getModulatorOffset := $08;
  4: getModulatorOffset := $09;
  5: getModulatorOffset := $0A;

  6: getModulatorOffset := $10;
  7: getModulatorOffset := $11;
  8: getModulatorOffset := $12;
  end;
end;

function getCarrierOffset(const voice: byte): byte;
begin
  case voice of
  0: getCarrierOffset := $03;
  1: getCarrierOffset := $04;
  2: getCarrierOffset := $05;

  3: getCarrierOffset := $0B;
  4: getCarrierOffset := $0C;
  5: getCarrierOffset := $0D;

  6: getCarrierOffset := $13;
  7: getCarrierOffset := $14;
  8: getCarrierOffset := $15;
  end;
end;

procedure setupInstrument(const voice: byte; var instr: PInstrument);
var
  { modulator & carrier offsets }
  modOffset, carOffset: byte;
begin
  modOffset := getModulatorOffset(voice);
  carOffset := getCarrierOffset(voice);

  if instr = nil then panicHalt('setupInstrument: instr is nil!');
  
  { Set up modulator }
  with instr^.modulator do begin
    AdLibWrite($20 + modOffset,
      (ord(tremolo) shl 7) or
      (ord(vibrato) shl 6) or
      (ord(sustain) shl 5) or
      (ord(keyScale) shl 4) or multiplier);
      
    AdLibWrite($40 + modOffset, (ord(keyScale) and 1) shl 6 or totalLevel);
    AdLibWrite($60 + modOffset, (attack shl 4) or decay);
    AdLibWrite($80 + modOffset, (sustainLevel shl 4) or release);
    AdLibWrite($e0 + modOffset, waveform)
  end;
  
  { Set up carrier }
  with instr^.carrier do begin
    AdLibWrite($20 + carOffset,
      (ord(tremolo) shl 7) or
      (ord(vibrato) shl 6) or
      (ord(sustain) shl 5) or
      (ord(keyScale) shl 4) or multiplier);
      
    AdLibWrite($40 + carOffset, (ord(keyScale) and 1) shl 6 or totalLevel);
    AdLibWrite($60 + carOffset, (attack shl 4) or decay);
    AdLibWrite($80 + carOffset, (sustainLevel shl 4) or release);
    AdLibWrite($e0 + carOffset, waveform)
  end;
  
  { Set algorithm and feedback }
  AdLibWrite($C0 + voice, (instr^.feedback shl 1) or instr^.algorithm)
end;

procedure TAdLibDriver.loadInstrument(const slot: byte; const instr: PInstrument);
begin
  if instr = nil then panicHalt('TAdLibDriver.loadInstrument: Attempting to load a nil instrument');
  if slot >= MAX_INSTRUMENTS then exit;

  instruments[slot] := instr
end;

procedure TAdLibDriver.selectInstrument(const voice, slot: byte);
begin
  if voice >= MAX_VOICES then exit;
  if slot >= MAX_INSTRUMENTS then exit;
  voices[voice].instrument := slot;
  setupInstrument(voice, instruments[slot])
end;


procedure resetAllRegisters;
var
  a: byte;
begin
  for a := $20 to $F5 do
    AdLibWrite(a, 0);
end;


function TAdLibDriver.getIsInitialised: boolean;
begin
  getIsInitialised := isInitialised
end;


{ Adapted from ccodere/pascal-adlib's GitHub repo }
procedure TAdLibDriver.setPercussive(const value: boolean);
begin
  isPercussive := value;
  { TODO: set the instruments }

  if value then begin
    { Skipped voices & setting BDRegister values }
    AdLibWrite($BD, $E0);
    { setRhythmInstruments; }
  end else begin
    AdLibWrite($BD, $C0);
    { setMelodicInstruments; }
  end;
end;

procedure TAdLibDriver.setMelodicInstruments;
begin
  { TODO: Not implemented! }
end;

procedure TAdLibDriver.setRhythmInstruments;
begin
  { TODO: Not implemented! }
end;

{ Adapted from BoardInstalled from ccodere/pascal-adlib }
function checkAdLib: boolean;
var
  status1, status2: integer;
begin
  AdLibWrite($04, $60);  { Reset both timers }
  AdLibWrite($04, $80);  { Enable timer interrupts }
  status1 := Port[StatusPort];

  AdLibWrite($02, $FF);
  AdLibWrite($04, $21);  { Start timer 21h }
  delay(100);  { Important }

  status2 := Port[StatusPort];
  AdLibWrite($04, $60);  { Reset both timers }
  AdLibWrite($04, $80);  { Enable timer interrupts }

  status1 := status1 and $E0;
  status2 := status2 and $E0;
  checkAdLib := (status1 = $00) and (status2 = $C0)
end;

procedure TAdLibDriver.init;
var
  a: byte;
begin
  if isInitialised then exit;

  if not checkAdLib then begin
    writeLog('TAdLibDriver.init: Can''t find the AdLib card!');
    exit
  end;

  resetAllRegisters;

  { Let us decide which waveforms we wish to have }
  AdLibWrite($01, $20);
  { Set key-scaling to ON }
  AdLibWrite($08, $40);
  
  for a := 0 to MAX_VOICES-1 do begin
    voices[a].active := false;
    voices[a].melody := nil;
    voices[a].noteIndex := 0;
    voices[a].noteEndTick := 0;
    voices[a].instrument := 0;
    voices[a].volume := 127
  end;
  
  isInitialised := true;

  setPercussive(false);
end;

{ Only for melodic voice }
{ TODO: Add the percussive mode }
procedure keyOn(const voice, freqLow, freqHigh: byte);
begin
  if voice >= MAX_VOICES then exit;

  AdLibWrite($A0 + voice, freqLow); { low byte of frequency }
  AdLibWrite($B0 + voice, freqHigh or $20) { high byte + key-on flag }
end;

{ Only for melodic voice }
{ TODO: Add the percussive mode }
procedure keyOff(const voice: byte);
begin
  if voice >= MAX_VOICES then exit;
  AdLibWrite($B0 + voice, 0)
end;


procedure TAdLibDriver.playNote(const voice: byte; const freq: word; const octave, velocity: byte);
var
  volume: byte;
  carrierOffset: byte;
begin
  if voice >= MAX_VOICES then exit;

  { Calculate carrier offset }
  case voice of
    0..2: carrierOffset := $03 + voice;
    3..5: carrierOffset := $0B + (voice - 3);
    6..8: carrierOffset := $13 + (voice - 6);
  end;
  
  volume := (velocity * voices[voice].volume) div 127;

  { TODO: Implement master volume }
  
  with instruments[voices[voice].instrument]^.carrier do
    AdLibWrite($40 + carrierOffset, (63 - (volume div 2)) and $3F);

  keyOn(
    voice,
    lo(freq),
    (hi(freq) and $03) or (octave shl 2))
end;


procedure TAdLibDriver.stopVoice(const voice: byte);
begin
  if voice >= MAX_VOICES then exit;
  AdLibWrite($B0 + voice, 0);
  voices[voice].active := false
end;

procedure TAdLibDriver.stopAllVoices;
var
  a: byte;
begin
  for a:=0 to MAX_VOICES - 1 do
    stopVoice(a);
end;

{ TODO: set volume }

procedure TAdLibDriver.playMelody(const melody: PMelody; const voice: byte);
var
  found: boolean;
begin
  stopVoice(voice);

  if melody = nil then panicHalt('TAdLibDriver.playMelody: Attempting to play a nil melody!');
  
  voices[voice].active := true;
  voices[voice].melody := melody;
  voices[voice].noteIndex := 0;
  voices[voice].noteEndTick := getTimer + melody^.notes[0].duration;
  voices[voice].instrument := melody^.instrument;

  setupInstrument(voice, instruments[melody^.instrument]);
  playNote(voice, melody^.notes[0].freq, melody^.notes[0].octave, melody^.notes[0].velocity)
end;


procedure TAdLibDriver.update;
var
  a: byte;
  now: double;
begin
  if not isInitialised then exit;
  
  now := getTimer;
  
  for a:=0 to MAX_VOICES-1 do begin
    if not voices[a].active then continue;
    
    if now >= voices[a].noteEndTick then begin
      keyOff(a);
      inc(voices[a].noteIndex);
      
      if voices[a].noteIndex >= voices[a].melody^.noteCount then begin
        voices[a].active := false;
        continue
      end;
      
      with voices[a].melody^.notes[voices[a].noteIndex] do begin
        playNote(a, freq, octave, velocity);
        voices[a].noteEndTick := now + duration
      end;
    end;
  end;
end;


procedure TAdLibDriver.shutdown;
begin
  if not isInitialised then exit;
  
  stopAllVoices;
  resetAllRegisters;

  isInitialised := false
end;

end.
