unit AdLib;

interface

type
  TAdLib = object
    var
	  isInitialised: boolean;
    procedure init;
	procedure shutdown;
	
	procedure loadInstrument(const slot: byte; var instrument: TInstrument);
	
    procedure startMelody;
	{ Playback }
    procedure playNote(const freq: word; const octave: byte);
	
	procedure playSFX(var sfx: TSFX);
    procedure update;
  end;

var
  AdLibDrv: TAdLib;

implementation

uses crt, timing;

type
  TInstrument = record
    modulator: TInstParams;
	carrier: TInstParams;
	feedback: byte;
	algorithm: byte;  { 0 = FM, 1 = Additive }
  end;
  TInstParams = record
    tremolo: boolean;
	vibrato: boolean;
	sustain: boolean;
	keyScale: boolean;
	multiplier, totalLevel, sustainLevel: byte;
	attack, decay, release, waveform: byte;
  end;
  TSFX = record
    notes: array[0..15] of TNote;
	count: byte;
	instrument: byte;
	priority: byte;
  end;
  
  TNote = record
    freq: word;
    octave: byte;
    durationMS: word;
  end;

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
  {
  currentNoteIndex: byte;
  melodyEndTick: longint;
  isPlaying: boolean;
  activeMelody: TMelody;
  }
  

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
	modulator.multiplier := false;
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
    AdlibWrite(i, 0);
	
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


procedure TAdlib.playNote(freq: word; octave: byte);
var
  freqLow, freqHigh: byte;
begin
  freqLow := lo(freq);
  freqHigh := (hi(freq) and $03) or (octave shl 2);
  keyOn(0, freqLow, freqHigh);
  { TODO: Update this with channels }
end;

procedure TAdLib.stopNote(const channel: byte);
begin
  if channel >= MAX_CHANNELS then exit;
  AdLibWrite($B0 + channel, 0);
  channels[channel].active := false
end;

{procedure TAdlib.playMelody;
begin}
  { F-number base with block=4 (middle octave) }
  {playNote($157, 4);
  playNote($181, 4);
  playNote($1ab, 4);
end;}

procedure TAdlib.startMelody;
begin
  { C D E }
  activeMelody.count := 3;
  with activeMelody.notes[0] do begin
    freq := $157; octave := 4; durationMS := 50;
  end;
  with activeMelody.notes[1] do begin
    freq := $181; octave := 4; durationMS := 50;
  end;
  with activeMelody.notes[2] do begin
    freq := $1AB; octave := 4; durationMS := 50;
  end;

  currentNoteIndex := 0;
  isPlaying := true;
  melodyEndTick := trunc(timer) + (activeMelody.notes[0].durationMS div 55);
  playNote(activeMelody.notes[0].freq, activeMelody.notes[0].octave)
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
