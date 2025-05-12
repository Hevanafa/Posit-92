{ PC speaker unit }

unit PCS;

interface

type
  TNote = record
    freq: word; { in Hz }
    durationMS: word; { in ms }
  end;

procedure playBeep(freq, durationMs: word);
procedure initPCS;
procedure startMelody;
procedure updateMelody;


implementation

uses crt, dos, Timing;

var
  PCS_currentNote: integer;
  PCS_noteEndTick: longint;
  PCS_playing: boolean;
  PCS_toneEnd: longint;

const
  { TODO: Add more of your sounds here }
  { C4 E4 G4 }
  melody: array[0..2] of TNote = (
    (freq: 261; durationMS: 100),
    (freq: 329; durationMS: 100),
    (freq: 392; durationMS: 100)
  );


procedure playBeep(freq, durationMs: word);
begin
  sound(freq);
  PCS_toneEnd := getTicks + (durationMs div 55);
  PCS_playing := true
end;


procedure playNextNote;
begin
  inc(PCS_currentNote);
  if PCS_currentNote > high(melody) then begin
    noSound;
    PCS_playing := false;
    exit;
  end;

  sound(melody[PCS_currentNote].freq);
  PCS_noteEndTick := getTicks + (melody[PCS_currentNote].durationMS div 55)
end;

procedure initPCS;
begin
  PCS_currentNote := -1;
  PCS_playing := false;
end;

procedure startMelody;
begin
  if PCS_playing then exit;
  PCS_currentNote := -1;
  PCS_playing := true;
  playNextNote;
end;

procedure updateMelody;
begin
  if PCS_playing and (getTicks >= PCS_noteEndTick) then
    playNextNote;
end;


end.
