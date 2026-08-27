{
  AdLib FM synthesiser interface utility unit
  Part of Posit-92 game engine
  Some parts are adapted from ccodere/pascal-adlib's GitHub repo
}

{$DEFINE DEBUG}

unit AdLib;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

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

  TInstrParams = record
    tremolo: boolean;
    vibrato: boolean;
    sustain: boolean;
    keyScale: boolean;
    multiplier: byte;
    totalLevel: byte;
    attackRate, decayRate: byte;
    sustainRate, releaseRate: byte;
    waveform: byte;
  end;

  PInstrument = ^TInstrument;
  TInstrument = record
    modulator: TInstrParams;
    carrier: TInstrParams;
    feedback: byte;
    algorithm: byte;  { 0 = FM, 1 = Additive }
  end;

  PMelody = ^TMelody;
  TMelody = record
    notes: array[0..15] of TNote; { TODO: Convert this into `PNoteArray` }
    noteCount: byte;
    instrument: PInstrument;
  end;

function GetIsInitialised: boolean;
procedure Init;
procedure Update;
procedure Shutdown;

procedure AssignInstrument(const voice: byte; const instr: PInstrument);

{ Playback }
procedure PlayMelody(const melody: PMelody; const voice: byte);
procedure PlayNote(const voice: byte; const freq: word; const octave, velocity: byte);
procedure StopVoice(const voice: byte);
procedure StopAllVoices;

procedure DrawDebug;

procedure InitNote(
  var note: TNote;
  const freq: word;
  const octave: byte;
  const duration: double;
  const velocity: byte);


implementation

uses
  CRT,
  P92CONV, P92LOG, P92PANIC, P92TIME, P92VGA;

type
  TVoiceState = record
    active: boolean;
    melody: PMelody;
    noteIndex: byte;
    noteEndTick: double; { in seconds }
    instrument: PInstrument;
    volume: byte; { 0..127 }
  end;

const
  AddressPort = $388;  { Address / status port }
  StatusPort = $388;
  DataPort = $389;

  MaxMelodicVoices = 9; { indices 0..8 }

var
  isInitialised: boolean;
  BDRegister: byte;
  voices: array[0..MaxMelodicVoices-1] of TVoiceState;

function GetIsInitialised: boolean;
begin
  GetIsInitialised := isInitialised
end;

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
procedure InitNote(
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

function GetModulatorOffset(const voice: byte): byte;
const
  offsets: array[0..8] of byte = (
    $00, $01, $02,
    $08, $09, $0A,
    $10, $11, $12
  );
begin
  GetModulatorOffset := offsets[voice]
end;

function GetCarrierOffset(const voice: byte): byte;
const
  offsets: array[0..8] of byte = (
    $03, $04, $05,
    $0B, $0C, $0D,
    $13, $14, $15
  );
begin
  GetCarrierOffset := offsets[voice]
end;


procedure AssignInstrument(const voice: byte; const instr: PInstrument);
var
  { modulator & carrier offsets }
  modOffset, carOffset: byte;
begin
  if instr = nil then panicHalt('assignInstrument: instr is nil!');
  
  modOffset := GetModulatorOffset(voice);
  carOffset := GetCarrierOffset(voice);

  { Set up modulator }
  with instr^.modulator do begin
    AdLibWrite($20 + modOffset,
      (ord(tremolo) shl 7) or
      (ord(vibrato) shl 6) or
      (ord(sustain) shl 5) or
      (ord(keyScale) shl 4) or multiplier);
      
    AdLibWrite($40 + modOffset, (ord(keyScale) and 1) shl 6 or totalLevel);
    AdLibWrite($60 + modOffset, (attackRate shl 4) or decayRate);
    AdLibWrite($80 + modOffset, (sustainRate shl 4) or releaseRate);
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
    AdLibWrite($60 + carOffset, (attackRate shl 4) or decayRate);
    AdLibWrite($80 + carOffset, (sustainRate shl 4) or releaseRate);
    AdLibWrite($e0 + carOffset, waveform)
  end;
  
  { Set algorithm and feedback }
  AdLibWrite(
    $C0 + voice,
    (instr^.feedback shl 1) or instr^.algorithm)
end;


procedure ResetAllRegisters;
var
  a: byte;
begin
  for a := $20 to $F5 do
    AdLibWrite(a, 0);
end;


{ Adapted from BoardInstalled from ccodere/pascal-adlib }
function CheckAdLib: boolean;
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
  CheckAdLib := (status1 = $00) and (status2 = $C0)
end;


{ low-level interface, doesn't change the `active` flag }
procedure MelodicKeyOn(const voice, freqLow, freqHigh: byte);
begin
  if voice >= MaxMelodicVoices then exit;

  AdLibWrite($A0 + voice, freqLow);  { low byte of frequency }
  AdLibWrite($B0 + voice, freqHigh or $20)  { high byte + key-on flag }
end;


{ low-level interface, doesn't change the `active` flag }
procedure MelodicKeyOff(const voice: byte);
begin
  if voice >= MaxMelodicVoices then exit;

  AdLibWrite($B0 + voice, 0);
end;


procedure PlayMelody(const melody: PMelody; const voice: byte);
begin
  StopVoice(voice);

  if melody = nil then panicHalt('playMelody: Attempting to play a nil melody!');

  voices[voice].active := true;
  voices[voice].melody := melody;
  voices[voice].noteIndex := 0;
  voices[voice].noteEndTick := getTimer + melody^.notes[0].duration;
  voices[voice].instrument := melody^.instrument;

  AssignInstrument(voice, voices[voice].instrument);

  PlayNote(
    voice,
    melody^.notes[0].freq,
    melody^.notes[0].octave,
    melody^.notes[0].velocity)
end;

procedure PlayNote(
  const voice: byte;
  const freq: word;
  const octave, velocity: byte);
var
  volume: byte;
  carrierOffset: byte;
begin
  if voice >= MaxMelodicVoices then exit;

  carrierOffset := GetCarrierOffset(voice);

  volume := (velocity * voices[voice].volume) div 127;

  AdLibWrite($40 + carrierOffset, ($3F - (volume div 2)) and $3F);

  MelodicKeyOn(
    voice,
    lo(freq),
    (hi(freq) and $03) or (octave shl 2))
end;

procedure StopVoice(const voice: byte);
begin
  if voice >= MaxMelodicVoices then exit;

  MelodicKeyOff(voice);
  voices[voice].active := false
end;

procedure StopAllVoices;
var
  a: byte;
begin
  for a:=0 to MaxMelodicVoices - 1 do
    StopVoice(a);
end;


procedure Init;
var
  a: byte;
begin
  if isInitialised then exit;

  if not CheckAdLib then begin
    writeLog('init: Can''t find the AdLib card!');
    exit
  end;

  ResetAllRegisters;

  { Let us decide which waveforms we wish to have }
  AdLibWrite($01, $20);
  { Set key-scaling to ON }
  AdLibWrite($08, $40);

  for a := 0 to MaxMelodicVoices-1 do begin
    voices[a].active := false;
    voices[a].melody := nil;
    voices[a].noteIndex := 0;
    voices[a].noteEndTick := 0;
    voices[a].instrument := nil;
    voices[a].volume := 127
  end;

  { Select SINUS Waves for Output }
  for a:=0 to 8 do begin
    AdLibWrite($E0 + GetModulatorOffset(a), $00);
    AdLibWrite($E0 + GetCarrierOffset(a), $00);
  end;

  BDRegister := $C0;
  AdLibWrite($BD, BDRegister);

  isInitialised := true;
end;

procedure Update;
var
  a: byte;
  now: double;
begin
  if not isInitialised then exit;
  
  now := GetTimer;
  
  for a:=0 to MaxMelodicVoices-1 do begin
    if not voices[a].active then continue;
    
    if now >= voices[a].noteEndTick then begin
      MelodicKeyOff(a);
      inc(voices[a].noteIndex);
      
      if voices[a].noteIndex >= voices[a].melody^.noteCount then begin
        voices[a].active := false;
        continue
      end;
      
      with voices[a].melody^.notes[voices[a].noteIndex] do begin
        PlayNote(a, freq, octave, velocity);
        voices[a].noteEndTick := now + duration
      end;
    end;
  end;
end;


procedure DrawDebug;
begin
  if not isInitialised then begin
    Print('AdLib is not initialised!', 0, 0, 7);
    exit
  end;

  Print('$BD: ' + I32Str(BDRegister), 0, 8, 7);
end;


procedure Shutdown;
begin
  if not isInitialised then exit;
  
  StopAllVoices;
  ResetAllRegisters;

  isInitialised := false
end;

end.
