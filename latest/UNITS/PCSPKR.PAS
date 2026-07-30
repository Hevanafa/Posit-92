{
  PC speaker unit
  Part of Posit-92 game engine
  By Hevanafa
}

unit PCSPKR;

{$IFDEF FPC}
{$MODE TP}
{$ENDIF}

interface

type
  TNote = record
    { in Hz }
    freq: word;

    { this field makes the note silent }
    rest: boolean;

    { in seconds }
    duration: double;
  end;

  PMelodyNotes = ^TMelodyNotes;
  { Placeholder range. The actual implementation relies on noteCount }
  TMelodyNotes = array[0..255] of TNote;

  PMelody = ^TMelody;
  TMelody = record
    notes: PMelodyNotes;
    noteCount: byte;
  end;

procedure Init;
procedure PlayBeep(const freq, durationMs: word);
procedure Stop;
procedure Update;

{
  freq: in Hz, 0 makes it a "rest"
  duration: in seconds
}
procedure InitNote(var output: TNote; const freq: word; const duration: double);

procedure CreateMelody(var mel: TMelody; const noteCount: byte);
procedure FreeMelody(var mel: TMelody);

{ The melody is borrowed from the user's assets }
procedure PlayMelody(const mel: PMelody);


implementation

uses CRT, DOS, Timing;

var
  isPlaying: boolean;
  currentNote: integer;
  currentMelody: PMelody;
  noteEndTick: double;


procedure InitNote(var output: TNote; const freq: word; const duration: double);
begin
  output.rest := freq = 0;
  if not output.rest then
    output.freq := freq;
  output.duration := duration
end;


procedure PlayBeep(const freq, durationMs: word);
begin
  sound(freq);
  noteEndTick := GetTimer + durationMs / 1000;
  isPlaying := true
end;


procedure PlayNextNote;
begin
  inc(currentNote);

  if currentNote >= currentMelody^.noteCount then begin
    Stop;
    exit
  end;

  NoSound;

  if not currentMelody^.notes^[currentNote].rest then
    Sound(currentMelody^.notes^[currentNote].freq);

  noteEndTick := GetTimer + currentMelody^.notes^[currentNote].duration;
end;

procedure Init;
begin
  currentNote := -1;
  isPlaying := false;
end;

procedure CreateMelody(var mel: TMelody; const noteCount: byte);
begin
  getmem(mel.notes, sizeof(TNote) * noteCount);
  mel.noteCount := noteCount;
end;

procedure FreeMelody(var mel: TMelody);
begin
  if mel.noteCount = 0 then exit;

  FreeMem(mel.notes, sizeof(TNote) * mel.noteCount);
  mel.noteCount := 0;
end;

procedure PlayMelody(const mel: PMelody);
begin
  if isPlaying then exit;
  if mel^.noteCount = 0 then exit;

  currentNote := -1;
  currentMelody := mel;
  isPlaying := true;
  playNextNote
end;

procedure Update;
begin
  if isPlaying and (getTimer >= noteEndTick) then
    playNextNote;
end;

procedure Stop;
begin
  noSound;
  isPlaying := false;
end;

end.
