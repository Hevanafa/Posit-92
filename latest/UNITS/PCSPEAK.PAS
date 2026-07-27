{
  PC speaker unit
  Part of Posit-92 game engine
  By Hevanafa
}

unit PCSpeaker;

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
    procedure Init;
    procedure PlayBeep(const freq, durationMs: word);
    procedure PlayMelody(const melody: TMelody);
    procedure Stop;
    procedure Update;
  end;

var
  PCSpeaker: TPCSpeaker;

procedure InitNote(var output: TNote; const freq: word; const duration: double);


implementation

uses CRT, DOS, Timing;

var
  currentNote: integer;
  currentMelody: TMelody;
  noteEndTick: double;
  playing: boolean;
  toneEnd: longint;


procedure InitNote(var output: TNote; const freq: word; const duration: double);
begin
  output.rest := freq = 0;
  if not output.rest then
    output.freq := freq;
  output.duration := duration
end;


procedure TPCSpeaker.PlayBeep(const freq, durationMs: word);
begin
  sound(freq);
  toneEnd := getTicks + (durationMs div 55);
  playing := true
end;


procedure playNextNote;
begin
  inc(currentNote);

  if currentNote >= currentMelody.noteCount then begin
    PCSpeaker.Stop;
    exit
  end;

  noSound;

  if not currentMelody.notes[currentNote].rest then
    sound(currentMelody.notes[currentNote].freq);

  noteEndTick := getTimer + currentMelody.notes[currentNote].duration;
end;

procedure TPCSpeaker.Init;
begin
  currentNote := -1;
  playing := false;
end;

procedure TPCSpeaker.PlayMelody(const melody: TMelody);
begin
  if playing then exit;

  currentNote := -1;
  currentMelody := melody;
  playing := true;
  playNextNote
end;

procedure TPCSpeaker.Update;
begin
  if playing and (getTimer >= noteEndTick) then
    playNextNote;
end;

procedure TPCSpeaker.Stop;
begin
  noSound;
  playing := false;
end;

end.
