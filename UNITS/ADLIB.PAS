{
  AdLib FM synthesiser interface utility unit
  Part of Posit-92 game framework
  Some parts are adapted from ccodere/pascal-adlib's GitHub repo
}

{ TODO: Maybe the percussive mode needs another set of NoteOn & NoteOff }

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
    multiplier, totalLevel: byte;
    sustainLevel, release: byte;
    attack, decay: byte;
    waveform: byte;
  end;
  PInstrument = ^TInstrument;
  TInstrument = record
    modulator: TInstrParams;
    carrier: TInstrParams;
    feedback: byte;
    algorithm: byte;  { 0 = FM, 1 = Additive }
  end;

  TOldInstrument = Record
    WaveChar: Byte;       { Wave Characteristic         }
    ScalingOutput: Byte;  { Scaling Level / Ouput level }
    AttackDecay: Byte;    { Attack / Decay Rate         }
    SustainRelease: Byte; { Sustain / Release Rate      }
    Feedback: Byte;       { Feedback                    }
    SetWaveSelect: Byte;  { Type of Wave to use         }
  end;

  PAdLibDriver = ^TAdLibDriver;
  TAdLibDriver = object
    function getIsInitialised: boolean;
    procedure init;
    procedure update;
    procedure shutdown;
    procedure setPercussive(const value: boolean);    

    procedure loadInstrument(const instrSlot: byte; const instr: PInstrument);
    procedure selectInstrument(const voice, instrSlot: byte);
    procedure setupMelodicInstruments;
    procedure setupRhythmInstruments;

    { Playback }
    procedure playNote(const voice: byte; const freq: word; const octave, velocity: byte);
    procedure stopVoice(const voice: byte);
    
    procedure playMelodyNoInstrument(const melody: PMelody; const voice: byte);
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

  MAX_MELODIC_VOICES = 9; { indices 0..8 }
  MAX_PERCUSSIVE_VOICES = 6; { for melodies: indices 0..5, percussions: 6, 7, 8 }
  MAX_INSTRUMENTS = 16; { indices 0..15 }

  { Percussive voice numbers }
  BassDrumVoice = 6;
  SnareDrumVoice = 7;
  TomTomVoice = 8;
  CymbalVoice = 9;
  HiHatVoice = 10;

  BassDrumBit = $10;
  SnareDrumBit = $08;
  TomTomBit = $04;
  CymbalBit = $02;
  HiHatBit = $01;

  PercussionBits: array[0..4] of byte =
    { $10, $08, $04, $02, $01 }
    (BassDrumBit, SnareDrumBit, TomTomBit, CymbalBit, HiHatBit);


var
  isInitialised: boolean;
  isPercussiveMode: boolean;
  BDRegister: byte;
  voices: array[0..MAX_MELODIC_VOICES-1] of TVoiceState;
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
const
  offsets: array[0..8] of byte = (
    $00, $01, $02,
    $08, $09, $0A,
    $10, $11, $12
  );
begin
  getModulatorOffset := offsets[voice]
end;

function getCarrierOffset(const voice: byte): byte;
const
  offsets: array[0..8] of byte = (
    $03, $04, $05,
    $0B, $0C, $0D,
    $13, $14, $15
  );
begin
  getCarrierOffset := offsets[voice]
end;


procedure setupInstrument(const voice: byte; var instr: PInstrument);
var
  { modulator & carrier offsets }
  modOffset, carOffset: byte;
begin
  if instr = nil then panicHalt('setupInstrument: instr is nil!');
  
  modOffset := getModulatorOffset(voice);
  carOffset := getCarrierOffset(voice);

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
  AdLibWrite(
    $C0 + voice,
    (instr^.feedback shl 1) or instr^.algorithm)
end;

{ Loads a PInstrument to a slot }
procedure TAdLibDriver.loadInstrument(const instrSlot: byte; const instr: PInstrument);
begin
  if instr = nil then panicHalt('TAdLibDriver.loadInstrument: Attempting to load a nil instrument');
  if instrSlot >= MAX_INSTRUMENTS then exit;

  instruments[instrSlot] := instr
end;

procedure TAdLibDriver.selectInstrument(const voice, instrSlot: byte);
begin
  if voice >= MAX_MELODIC_VOICES then exit;
  if instrSlot >= MAX_INSTRUMENTS then exit;

  voices[voice].instrument := instrSlot;
  setupInstrument(voice, instruments[instrSlot])
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
  isPercussiveMode := value;

  if value then begin
    { Skipped MaxVoices value }
    BDRegister := $E0;
    AdLibWrite($BD, BDRegister);
    setupRhythmInstruments;
  end else begin
    BDRegister := $C0;
    AdLibWrite($BD, BDRegister);
    setupMelodicInstruments;
  end;
end;

{ Assigns all voices with the electric piano preset }
procedure TAdLibDriver.setupMelodicInstruments;
const
  OpModulator: array[0..13] of byte = (
    $00, $01, $02, $08, $09, $0a,
    $10, $11, $12, $01, $11, $4f,
    $00, $f1);
  { Todo: adapt this with the TInstrument format }
  ElectricPiano: array[0..1] of TOldInstrument = (
  (
    WaveChar: 65; ScalingOutput: 127;
    AttackDecay: 242; SustainRelease: 81;
    FeedBack: 7; SetWaveSelect: 1),

  (
    WaveChar: 19; ScalingOutput: 0;
    AttackDecay: 242; SustainRelease: 241;
    FeedBack: 0; SetWaveSelect: 0));
var
  voice, op, portOffset: byte;
begin
  for voice:=0 to MAX_MELODIC_VOICES do begin
    { 0: Modulator, 1: Carrier }
    for op:=0 to 1 do begin
      if op = 0 then portOffset := 0 else portOffset := 3;

      AdLibWrite($20 + portOffset + OpModulator[voice],
        ElectricPiano[0].WaveChar);

      AdLibWrite($40 + portOffset + OpModulator[voice],
        ElectricPiano[0].ScalingOutput);

      AdLibWrite($60 + portOffset + OpModulator[voice],
        ElectricPiano[0].AttackDecay);

      AdLibWrite($80 + portOffset + OpModulator[voice],
        ElectricPiano[0].SustainRelease);

      AdLibWrite($E0 + portOffset + OpModulator[voice],
        ElectricPiano[0].SetWaveSelect);
    end;

    AdLibWrite($C0 + voice, ElectricPiano[0].FeedBack)
  end;
end;


procedure TAdLibDriver.setupRhythmInstruments;
const
  OpModulator: array[0..10] of byte = (
    $F2, $53, $74, $00, $00, $08,
    $10, $14, $12, $15, $11
  );

  { PERCUSSIVE MODE VOICES }
  { TODO: Adapt this with the TInstrument format }
  BassDrum:array[0..1] of TOldInstrument = (
    { Modulator }
    (
      WaveChar: 0; ScalingOutput: 11;
      AttackDecay: $A8; SustainRelease: $4C;
      FeedBack: 1; SetWaveSelect: 1),

    { Carrier }
    (
      WaveChar: 0; ScalingOutput: 0;
      AttackDecay: $D6; SustainRelease: $4F;
      FeedBack: 1; SetWaveSelect: 0));

  InstrArray:Array[7..10] of TOldInstrument =
  (* SnareDrum Instrument *)
  ((
    WaveChar:12; ScalingOutput: 0;
    AttackDecay: 248; SustainRelease: 181;
    FeedBack: 0; SetWaveSelect: 0),

  (* TomTom Voice instrument *)
  (WaveChar: 4; ScalingOutput: 0;
    AttackDecay: 247; SustainRelease: 181;
    FeedBack: 0; SetWaveSelect: 0),
  (* Cymbal Voice Instrument *)
  (WaveChar: 1; ScalingOutput: 0;
    AttackDecay: 245; SustainRelease: 181;
    FeedBack: 0; SetWaveSelect: 0),
  (* hihat Voice Instrument *)
  (WaveChar: 1; ScalingOutput: 0;
    AttackDecay: 247; SustainRelease: 181;
    FeedBack: 0; SetWaveSelect: 0));
var
  a, opOffset: byte;
begin
  { Skipped Carrier up to Volume array accesses }

  opOffset := OpModulator[BassDrumVoice];

  { Modulator }
  with BassDrum[0] do begin
    AdLibWrite(opOffset + $20, WaveChar);
    AdLibWrite(opOffset + $40, ScalingOutput);
    AdLibWrite(opOffset + $60, AttackDecay);
    AdLibWrite(opOffset + $80, SustainRelease);
    AdLibWrite(BassDrumVoice + $C0, Feedback);
    AdLibWrite(opOffset + $E0, SetWaveSelect);
  end;

  { Carrier }
  with BassDrum[1] do begin
    AdLibWrite(opOffset + $23, WaveChar);
    AdLibWrite(opOffset + $43, ScalingOutput);
    AdLibWrite(opOffset + $63, AttackDecay);
    AdLibWrite(opOffset + $83, SustainRelease);
    AdLibWrite(opOffset + $E3, SetWaveSelect);
  end;
  
  for a:=SnareDrumVoice to HiHatVoice do begin
    opOffset := OpModulator[a];
    AdLibWrite(opOffset + $20, InstrArray[a].WaveChar);
    AdLibWrite(opOffset + $40, InstrArray[a].ScalingOutput);
    AdLibWrite(opOffset + $60, InstrArray[a].AttackDecay);
    AdLibWrite(opOffset + $80, InstrArray[a].SustainRelease);
    AdLibWrite(a + $C0, InstrArray[a].Feedback);
    AdLibWrite(opOffset + $E0, InstrArray[a].SetWaveSelect);
  end;
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


function getIsMelodic(const voice: byte): boolean;
begin
  getIsMelodic := (isPercussiveMode and (voice < BassDrumVoice)) or
    (not isPercussiveMode)
end;


procedure keyOn(const voice, freqLow, freqHigh: byte);
const
  PercussiveOffset: array[0..10] of byte = (
      $11, $10, $08, $04, $02, $01,
      $06, $07, $08, $08, $07);
var
  isMelodic: boolean;
begin
  if voice >= MAX_MELODIC_VOICES then exit;

  isMelodic := getIsMelodic(voice);

  if isMelodic then begin
    AdLibWrite($A0 + voice, freqLow); { low byte of frequency }
    AdLibWrite($B0 + voice, freqHigh or $20) { high byte + key-on flag }
  end else begin
    BDRegister := BDRegister OR PercussionBits[Voice - 6];
    AdLibWrite($A0 + PercussiveOffset[Voice], freqLow);
    AdLibWrite($B0 + PercussiveOffset[Voice], freqHigh);

    AdLibWrite($BD, BDRegister);
  end;
end;


procedure keyOff(const voice: byte);
var
  isMelodic: boolean;
begin
  if voice >= MAX_MELODIC_VOICES then exit;

  isMelodic := getIsMelodic(voice);

  if isMelodic then
    AdLibWrite($B0 + voice, 0)
  else begin
    BDRegister := BDRegister AND (NOT PercussionBits[Voice - 6]);
    AdLibWrite($BD, BDRegister);
  end;
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
  
  for a := 0 to MAX_MELODIC_VOICES-1 do begin
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

procedure TAdLibDriver.playNote(const voice: byte; const freq: word; const octave, velocity: byte);
var
  volume: byte;
  carrierOffset: byte;
begin
  if voice >= MAX_MELODIC_VOICES then exit;

  carrierOffset := getCarrierOffset(voice);

  volume := (velocity * voices[voice].volume) div 127;

  { Important: Don't delete this! }
  {
  with instruments[voices[voice].instrument]^.carrier do
    AdLibWrite($40 + carrierOffset, ($3F - (volume div 2)) and $3F);
  }
  AdLibWrite($40 + carrierOffset, ($3F - (volume div 2)) and $3F);

  keyOn(
    voice,
    lo(freq),
    (hi(freq) and $03) or (octave shl 2))
end;

procedure TAdLibDriver.stopVoice(const voice: byte);
begin
  if voice >= MAX_MELODIC_VOICES then exit;

  { AdLibWrite($B0 + voice, 0); }
  keyOff(voice);
  voices[voice].active := false
end;

procedure TAdLibDriver.stopAllVoices;
var
  a: byte;
begin
  for a:=0 to MAX_MELODIC_VOICES - 1 do
    stopVoice(a);
end;


procedure TAdLibDriver.playMelodyNoInstrument(const melody: PMelody; const voice: byte);
var
  found: boolean;
begin
  stopVoice(voice);

  if melody = nil then panicHalt('TAdLibDriver.playMelody: Attempting to play a nil melody!');
  
  voices[voice].active := true;
  voices[voice].melody := melody;
  voices[voice].noteIndex := 0;
  voices[voice].noteEndTick := getTimer + melody^.notes[0].duration;
  { voices[voice].instrument := melody^.instrument; }

  { setupInstrument(voice, instruments[melody^.instrument]); }
  playNote(
    voice,
    melody^.notes[0].freq,
    melody^.notes[0].octave,
    melody^.notes[0].velocity)
end;

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
  playNote(
    voice,
    melody^.notes[0].freq,
    melody^.notes[0].octave,
    melody^.notes[0].velocity)
end;


procedure TAdLibDriver.update;
var
  a: byte;
  now: double;
begin
  if not isInitialised then exit;
  
  now := getTimer;
  
  for a:=0 to MAX_MELODIC_VOICES-1 do begin
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
