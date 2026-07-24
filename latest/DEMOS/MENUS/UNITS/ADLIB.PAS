unit Adlib;

interface

type
  TAdlib = object
    procedure init;
    procedure startMelody;
    procedure playNote(freq: word; octave: byte);
    procedure update;
  end;

var
  AdlibDrv: TAdlib;

implementation

uses crt, timing;

type
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

const
  AdLibStatus = $388;
  AdLibData = $389;

var
  currentNoteIndex: byte;
  noteEndTick: longint;
  isPlaying: boolean;
  activeMelody: TMelody;

procedure AdlibWrite(reg, value: byte);
var
  a: byte;
begin
  { replaced delay with simulated delay }
  Port[AdlibStatus] := reg;
  for a:=1 to 10 do;
  Port[AdlibData] := value;
  for a:=1 to 10 do;
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
  i: byte;
begin
  for i := $20 to $f5 do
    AdlibWrite(i, 0);

  setupInstruments;
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
    freq := $157; octave := 3; durationMS := 50;
  end;
  with activeMelody.notes[1] do begin
    freq := $181; octave := 3; durationMS := 50;
  end;
  with activeMelody.notes[2] do begin
    freq := $1AB; octave := 3; durationMS := 50;
  end;

  currentNoteIndex := 0;
  isPlaying := true;
  noteEndTick := trunc(timer) + (activeMelody.notes[0].durationMS div 55);
  playNote(activeMelody.notes[0].freq, activeMelody.notes[0].octave)
end;

procedure TAdlib.update;
var
  now: longint;
begin
  if not isPlaying then exit;
  now := trunc(timer);

  if now >= noteEndTick then
  begin
    keyOff(0);
    inc(currentNoteIndex);
    if currentNoteIndex >= activeMelody.count then begin
      isPlaying := false;
      exit
    end;
    with activeMelody.notes[currentNoteIndex] do begin
      playNote(freq, octave);
      noteEndTick := now + (durationMS div 55)
    end;
  end;
end;

end.
