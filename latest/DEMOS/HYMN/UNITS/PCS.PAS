{ PC speaker unit }

unit PCS;

interface

type
  TNote = record
    freq: word; { in Hz }
    rest: boolean;
    duration: double; { in seconds }
  end;
  TMelody = record
    notes: array[0..127] of TNote;
    noteCount: byte;
  end;

  TPCSpeaker = object
    procedure init;
    procedure playBeep(const freq, durationMs: word);
    procedure playMelody(const melody: TMelody);
    procedure stop;
    procedure update;
  end;

var
  PCSpeaker: TPCSpeaker;

procedure initNote(var output: TNote; const freq: word; const duration: double);


implementation

uses CRT, DOS, Timing;

var
  currentNote: integer;
  currentMelody: TMelody;
  noteEndTick: double;
  playing: boolean;
  toneEnd: longint;


procedure initNote(var output: TNote; const freq: word; const duration: double);
begin
  output.rest := freq = 0;
  if not output.rest then
    output.freq := freq;
  output.duration := duration
end;


procedure TPCSpeaker.playBeep(const freq, durationMs: word);
begin
  sound(freq);
  toneEnd := getTicks + (durationMs div 55);
  playing := true
end;


procedure playNextNote;
begin
  inc(currentNote);

  if currentNote >= currentMelody.noteCount then begin
    PCSpeaker.stop;
    exit
  end;

  noSound;
  if not currentMelody.notes[currentNote].rest then
    sound(currentMelody.notes[currentNote].freq);

  noteEndTick := getTimer + currentMelody.notes[currentNote].duration;
end;

procedure TPCSpeaker.init;
begin
  currentNote := -1;
  playing := false;
end;

procedure TPCSpeaker.playMelody(const melody: TMelody);
begin
  if playing then exit;

  currentNote := -1;
  currentMelody := melody;
  playing := true;
  playNextNote
end;

procedure TPCSpeaker.update;
begin
  if playing and (getTimer >= noteEndTick) then
    playNextNote;
end;

procedure TPCSpeaker.stop;
begin
  noSound;
  playing := false;
end;

end.
