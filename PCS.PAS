{ PC speaker unit }

unit PCS;

interface

type
  TNote = record
    freq: word; { in Hz }
    durationMS: word; { in ms }
  end;

  TPCSpeaker = object
    procedure init;
    procedure playBeep(freq, durationMs: word);
    procedure startMelody;
    procedure updateMelody;
  end;

var
  PCSpeaker: TPCSpeaker;


implementation

uses crt, dos, Timing;

var
  currentNote: integer;
  noteEndTick: longint;
  playing: boolean;
  toneEnd: longint;

const
  { TODO: Add more of your sounds here }
  { C4 E4 G4 }
  melody: array[0..2] of TNote = (
    (freq: 261; durationMS: 100),
    (freq: 329; durationMS: 100),
    (freq: 392; durationMS: 100)
  );


procedure TPCSpeaker.playBeep(freq, durationMs: word);
begin
  sound(freq);
  toneEnd := getTicks + (durationMs div 55);
  playing := true
end;


procedure playNextNote;
begin
  inc(currentNote);
  if currentNote > high(melody) then begin
    noSound;
    playing := false;
    exit;
  end;

  sound(melody[currentNote].freq);
  noteEndTick := getTicks + (melody[currentNote].durationMS div 55)
end;

procedure TPCSpeaker.init;
begin
  currentNote := -1;
  playing := false;
end;

procedure TPCSpeaker.startMelody;
begin
  if playing then exit;
  currentNote := -1;
  playing := true;
  playNextNote;
end;

procedure TPCSpeaker.updateMelody;
begin
  if playing and (getTicks >= noteEndTick) then
    playNextNote;
end;


end.
