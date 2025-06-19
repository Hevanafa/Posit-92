{
  AdLib FM synthetiser utility unit
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
    
    procedure loadInstrument(const slot: byte; const instr: PInstrument);
    procedure selectInstrument(const voice, slot: byte);
    
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

uses CRT, Panic, Timing;

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
  DataPort = $389;  { Data port }
  
  MAX_VOICES = 9; { indices 0..8 }
  MAX_INSTRUMENTS = 16; { indices 0..15 }

var
  isInitialised: boolean;
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

procedure setupInstrument(const voice: byte; var instr: PInstrument);
var
  { modulator & carrier offsets }
  modOffset, carOffset: byte;
begin
  case voice of
    0: begin modOffset := $00; carOffset := $03; end;
    1: begin modOffset := $01; carOffset := $04; end;
    2: begin modOffset := $02; carOffset := $05; end;
    
    3: begin modOffset := $08; carOffset := $0b; end;
    4: begin modOffset := $09; carOffset := $0c; end;
    5: begin modOffset := $0A; carOffset := $0d; end;
    
    6: begin modOffset := $10; carOffset := $13; end;
    7: begin modOffset := $11; carOffset := $14; end;
    8: begin modOffset := $12; carOffset := $15; end;
  end;

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


procedure TAdLibDriver.init;
var
  a: byte;
begin
  if isInitialised then exit;

  resetAllRegisters;
  
  for a := 0 to MAX_VOICES-1 do begin
    voices[a].active := false;
    voices[a].melody := nil;
    voices[a].noteIndex := 0;
    voices[a].noteEndTick := 0;
    voices[a].instrument := 0;
    voices[a].volume := 127
  end;
  
  isInitialised := true
end;

procedure keyOn(const voice, freqLow, freqHigh: byte);
begin
  if voice >= MAX_VOICES then exit;
  AdLibWrite($A0 + voice, freqLow); { low byte of frequency }
  AdLibWrite($B0 + voice, freqHigh or $20) { high byte + key-on flag }
end;

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
