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
  TMelodyNotes = array[0..0] of TNote;
  TMelody = record
    notes: PMelodyNotes;
    noteCount: byte;
  end;

procedure Init;
procedure PlayBeep(const freq, durationMs: word);
procedure Stop;
procedure Update;

procedure InitNote(var output: TNote; const freq: word; const duration: double);

procedure CreateMelody(var mel: TMelody; const noteCount: byte);
procedure PlayMelody(const melody: TMelody);


implementation

uses CRT, DOS, Timing;

var
  currentNote: integer;
  currentMelody: TMelody;
  noteEndTick: double;
  playing: boolean;


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
  playing := true
end;


procedure PlayNextNote;
begin
  inc(currentNote);

  if currentNote >= currentMelody.noteCount then begin
    Stop;
    exit
  end;

  NoSound;

  if not currentMelody.notes^[currentNote].rest then
    Sound(currentMelody.notes^[currentNote].freq);

  noteEndTick := GetTimer + currentMelody.notes^[currentNote].duration;
end;

procedure Init;
begin
  currentNote := -1;
  playing := false;
end;

procedure CreateMelody(var mel: TMelody; const noteCount: byte);
begin
  getmem(mel.notes, sizeof(TNote));
  mel.noteCount := noteCount;
end;

procedure PlayMelody(const melody: TMelody);
begin
  if playing then exit;

  currentNote := -1;
  currentMelody := melody;
  playing := true;
  playNextNote
end;

procedure Update;
begin
  if playing and (getTimer >= noteEndTick) then
    playNextNote;
end;

procedure Stop;
begin
  noSound;
  playing := false;
end;

end.
