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

  { TSFX = record
    notes: array[0..15] of TNote;
    noteCount: byte;
    instrument: byte;
    priority: byte;
  end;
  }
  TInstrParams = record
    tremolo: boolean;
    vibrato: boolean;
    sustain: boolean;
    keyScale: boolean;
    multiplier, totalLevel, sustainLevel: byte;
    attack, decay, release, waveform: byte;
  end;
  TInstrument = record
    modulator: TInstrParams;
    carrier: TInstrParams;
    feedback: byte;
    algorithm: byte;  { 0 = FM, 1 = Additive }
  end;
  TAdLib = object
    procedure init;
    procedure update;
    procedure shutdown;
    
    procedure loadInstrument(const slot: byte; var instr: TInstrument);
    procedure selectInstrument(const channel, slot: byte);
    
    { Playback }
    procedure playNote(const channel: byte; const freq: word; const octave, velocity: byte);
    procedure stopNote(const channel: byte);
    
    procedure playMelody(const melody: PMelody; const channel: byte);
    procedure stopAllChannels;
  end;

var
  AdLibDrv: TAdLib;

procedure initNote(var result: TNote; const freq: word; const octave: byte; const duration: double; const velocity: byte);

implementation

uses CRT, Panic, Timing;

type
  TChannelState = record
    active: boolean;
    melody: PMelody;
    noteIndex: byte;
    noteEndTick: double; { in seconds }
    { isSFX: boolean; }
    { sfx: TSFX; }
    instrument: byte;
    volume: byte; { 0..127 }
  end;

const
  AdLibStatus = $388;
  AdLibData = $389;
  
  MAX_CHANNELS = 9;
  MAX_INSTRUMENTS = 16;
  

var
  PianoInstrument: TInstrument;
  isInitialised: boolean;
  channels: array[0..MAX_CHANNELS-1] of TChannelState;
  instruments: array[0..MAX_INSTRUMENTS-1] of TInstrument;


procedure AdLibWrite(const reg, value: byte);
var
  a: byte;
begin
  Port[AdlibStatus] := reg;
  for a:=1 to 10 do;  { simulated delay }
  Port[AdlibData] := value;
  for a:=1 to 10 do;  { simulated delay }
end;

{
  freq uses NOTE_ prefix
  octave is the same as "block" in AdLib
  duration is in seconds
  velocity: 0..127
}
procedure initNote(var result: TNote; const freq: word; const octave: byte; const duration: double; const velocity: byte);
begin
  result.freq := freq;
  result.octave := octave;
  result.duration := duration;
  result.velocity := velocity;
end;

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

procedure setupInstrument(const channel: byte; var instr: TInstrument);
var
  { modulator & carrier offsets }
  modOffset, carOffset: byte;
begin
  { Calculate operator offsets }
  case channel of
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
  
  { Set up modulator }
  with instr.modulator do begin
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
  with instr.carrier do begin
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
  AdLibWrite($C0 + channel, (instr.feedback shl 1) or instr.algorithm)
end;

procedure TAdLib.loadInstrument(const slot: byte; var instr: TInstrument);
begin
  if slot >= MAX_INSTRUMENTS then exit;
  instruments[slot] := instr
end;

procedure TAdLib.selectInstrument(const channel, slot: byte);
begin
  if (channel >= MAX_CHANNELS) or (slot >= MAX_INSTRUMENTS) then exit;
  channels[channel].instrument := slot;
  setupInstrument(channel, instruments[slot])
end;


procedure TAdLib.init;
var
  a: integer;
begin
  if isInitialised then exit;
  
  { Reset all registers }
  for a := $20 to $F5 do
    AdlibWrite(a, 0);
    
  for a := 0 to MAX_CHANNELS-1 do begin
    channels[a].active := false;
    channels[a].noteIndex := 0;
    channels[a].noteEndTick := 0;
    channels[a].melody := nil;
    { channels[a].isSFX := false; }
    channels[a].instrument := 0;
    channels[a].volume := 127
  end;

  initInstruments;
  loadInstrument(0, PianoInstrument);
  { Load more of your instruments here }
  
  isInitialised := true
end;

procedure keyOn(channel: byte; freqLow, freqHigh: byte);
begin
  adlibWrite($A0 + channel, freqLow); { low byte of frequency }
  adlibWrite($B0 + channel, freqHigh or $20) { high byte + key-on flag }
end;

procedure keyOff(channel: byte);
begin
  adlibWrite($B0 + channel, 0)
end;


procedure TAdLib.playNote(const channel: byte; const freq: word; const octave, velocity: byte);
var
  volume: byte;
begin
  if channel >= MAX_CHANNELS then exit;
  
  volume := (velocity * channels[channel].volume) div 127;
  { TODO: Implement master volume }
  
  with instruments[channels[channel].instrument].carrier do
    AdLibWrite($40 + channel + 3, (63 - (volume div 2)) and $3F);

  { keyOn(0, freqLow, freqHigh); }
  
  AdLibWrite($a0 + channel, lo(freq));
  AdLibWrite(
    $b0 + channel,
    (hi(freq) and $03) or (octave shl 2) or $20); { Key-on flag }
end;

procedure TAdLib.stopNote(const channel: byte);
begin
  if channel >= MAX_CHANNELS then exit;
  AdLibWrite($B0 + channel, 0);
  channels[channel].active := false
end;

{ TODO: set volume }


procedure TAdLib.playMelody(const melody: PMelody; const channel: byte);
var
  found: boolean;
begin
  stopNote(channel);

  if melody = nil then panicHalt('TAdLib.playMelody: Attempting to play a nil melody!');
  
  { channels[channel].isSFX := true; }
  { channels[channel].sfx := sfx; }
  channels[channel].active := true;
  channels[channel].melody := melody;
  channels[channel].noteIndex := 0;
  channels[channel].noteEndTick := getTimer + melody^.notes[0].duration;
  channels[channel].instrument := melody^.instrument;

  setupInstrument(channel, instruments[melody^.instrument]);
  playNote(channel, melody^.notes[0].freq, melody^.notes[0].octave, melody^.notes[0].velocity)
end;


procedure TAdLib.stopAllChannels;
var
  a: integer;
begin
  for a:=0 to MAX_CHANNELS - 1 do
    stopNote(a);
end;


procedure TAdLib.update;
var
  a: integer;
  now: double;
begin
  if not isInitialised then exit;
  
  now := getTimer;
  
  for a:=0 to MAX_CHANNELS-1 do begin
    if not channels[a].active then continue;
    
    if now >= channels[a].noteEndTick then begin
      stopNote(a);
      inc(channels[a].noteIndex);
      
      if channels[a].noteIndex >= channels[a].melody^.noteCount then begin
        channels[a].active := false;
        continue
      end;
      
      with channels[a].melody^.notes[channels[a].noteIndex] do begin
        playNote(a, freq, octave, velocity);
        channels[a].noteEndTick := now + duration
      end;
    end;
  end;
end;


procedure TAdLib.shutdown;
var
  a: byte;
begin
  if not isInitialised then exit;
  
  { Stop all channels }
  for a:=0 to MAX_CHANNELS-1 do
    stopNote(a);
  
  { Reset AdLib }
  for a := $20 to $F5 do
    AdLibWrite(a, 0);

  isInitialised := false
end;

end.
