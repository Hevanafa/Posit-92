unit AdLib;

interface

type
  TNote = record
    freq: word;
    octave: byte;
    duration: double;  { in seconds }
  end;
  TSFX = record
    notes: array[0..15] of TNote;
    count: byte;
    instrument: byte;
    priority: byte;
  end;
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
    procedure shutdown;
    
    procedure loadInstrument(const slot: byte; var instrument: TInstrument);
    
    { procedure startMelody; }
    { Playback }
    procedure playNote(const channel: byte; const freq: word; const octave, velocity: byte);
	procedure stopNote(const channel: byte);
    
    procedure playSFX(var sfx: TSFX);
    procedure update;
  end;

var
  AdLibDrv: TAdLib;

implementation

uses crt, timing;

type
  PMelody = ^TMelody;
  TMelody = record
    notes: array[0..15] of TNote;
    count: byte;
  end;
  
  TChannelState = record
    active: boolean;
    noteIndex: byte;
    endTime: double; { in seconds }
    { melody: PMelody; }
    isSFX: boolean;
    sfx: TSFX;
    instrument: byte;
    volume: byte; { 0..127 }
  end;

const
  AdLibStatus = $388;
  AdLibData = $389;
  
  MAX_CHANNELS = 9;
  MAX_INSTRUMENTS = 16;
  
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
  

var
  PianoInstrument: TInstrument;
  isInitialised: boolean;
  channels: array[0..MAX_CHANNELS-1] of TChannelState;
  instruments: array[0..MAX_INSTRUMENTS-1] of TInstrument;

  currentNoteIndex: byte;
  melodyEndTick: longint;
  isPlaying: boolean;
  activeMelody: TMelody;


procedure AdLibWrite(const reg, value: byte);
var
  a: byte;
begin
  Port[AdlibStatus] := reg;
  for a:=1 to 10 do;  { simulated delay }
  Port[AdlibData] := value;
  for a:=1 to 10 do;  { simulated delay }
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
begin
  panicHalt('Not implemented!')
end;

procedure setupInstruments;
begin
  adlibWrite($20, $01);  { tremolo off, vibrato off, sustain off, key scale off, mult = 1 }
  adlibWrite($40, $10);   { total level = 16 }
  adlibWrite($60, $F0);  { attack = F, decay = 0 }
  adlibWrite($80, $77);  { sustain 7, release 7 }
  adlibWrite($E0, $00);    { waveform select = 0 }

  { Carrier (actual sound) -- operator 3 for channel 0 }
  adlibWrite($23, $01);
  adlibWrite($43, $00);
  adlibWrite($63, $F0);
  adlibWrite($83, $77);
  adlibWrite($E3, $00);
end;


procedure TAdlib.init;
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
    channels[a].endTime := 0;
    { channels[a].melody := nil; }
    channels[a].isSFX := false;
    channels[a].instrument := 0;
    channels[a].volume := 127
  end;

  { setupInstruments; }
  
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


procedure TAdlib.playNote(const channel: byte; const freq: word; const octave, velocity: byte);
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

{procedure TAdlib.playMelody;
begin}
  { F-number base with block=4 (middle octave) }
  {playNote($157, 4);
  playNote($181, 4);
  playNote($1ab, 4);
end;}

{ TODO: Update this considering the channels }
procedure {TAdLib.}startMelody;
begin
  { C D E }
  activeMelody.count := 3;
  with activeMelody.notes[0] do begin
    freq := $157; octave := 4; duration := 0.050;
  end;
  with activeMelody.notes[1] do begin
    freq := $181; octave := 4; duration := 0.050;
  end;
  with activeMelody.notes[2] do begin
    freq := $1AB; octave := 4; duration := 0.050;
  end;

  currentNoteIndex := 0;
  isPlaying := true;
  {
    Disabled because it doesn't work with the
    latest version, which uses seconds instead of
    milliseconds
  }
  {
  melodyEndTick := trunc(timer) + (activeMelody.notes[0].durationMS div 55);
  playNote(activeMelody.notes[0].freq, activeMelody.notes[0].octave)
  }
end;


procedure TAdLib.playSFX(var sfx: TSFX);
var
  channel: byte;
  found: boolean;
begin
  { Find an available channel }
  found := false;
  { This can be changed to use the last 3 channels }
  for channel := 0 to 2 do begin
    if not channels[channel].active then begin
      found := true;
      break
    end;
  end;
  
  if not found then exit;
  
  stopNote(channel);
  
  channels[channel].isSFX := true;
  channels[channel].sfx := sfx;
  channels[channel].noteIndex := 0;
  channels[channel].active := true;
  channels[channel].instrument := sfx.instrument;
  channels[channel].endTime := getTimer + sfx.notes[0].duration;
  
  setupInstrument(channel, instruments[sfx.instrument]);
  playNote(channel, sfx.notes[0].freq, sfx.notes[0].octave, sfx.notes[0].velocity)
end;


procedure TAdLib.stopAllSFX;
var
  a: integer;
begin
  for a:=0 to 2 do
    if channels[a].isSFX then stopNote(a);
end;


procedure TAdLib.update;
var
  a: integer;
  now: longint;
begin
  if not isInitialised then exit;
  now := getTimerMS;
  
  for a:=0 to MAX_CHANNELS-1 do begin
    { TODO: Update channels }
  end;
end;


procedure TAdlib.shutdown;
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
