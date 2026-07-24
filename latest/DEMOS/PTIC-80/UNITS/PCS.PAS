{ PC speaker unit }

unit PCS;

interface

type
  SoundIDs = (
    Melody1,
    Melody2,
    Melody3
  );
  TNote = record
    freq: word; { in Hz }
    durationMS: word; { in ms }
  end;

  TPCSpeaker = object
    procedure init;
    procedure playBeep(freq, durationMs: word);
    procedure playMelody(id: SoundIDs);
    procedure updateMelody;
  end;

var
  PCSpeaker: TPCSpeaker;


implementation

uses crt, dos, Timing;

var
  currentNote: integer;
  currentID: SoundIDs;
  noteEndTick: longint;
  playing: boolean;
  toneEnd: longint;

const
  { TODO: Add more of your sounds here }
  { C4 E4 G4 }
  mel1: array[0..2] of TNote = (
    (freq: 261; durationMS: 100),
    (freq: 329; durationMS: 100),
    (freq: 392; durationMS: 100)
  );
  { D4 F#4 A4 }
  mel2: array[0..2] of TNote = (
    (freq: 293; durationMS: 100),
    (freq: 370; durationMS: 100),
    (freq: 440; durationMS: 100)
  );
  mel3: array[0..2] of TNote = (
    (freq: 329; durationMS: 100),
    (freq: 415; durationMS: 100),
    (freq: 494; durationMS: 100)
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
  if currentNote > high(mel1) then begin
    noSound;
    playing := false;
    exit;
  end;

  case currentID of
    Melody1: begin
      sound(mel1[currentNote].freq);
      noteEndTick := getTicks + (mel1[currentNote].durationMS div 55)
      end;
    Melody2: begin
      sound(mel2[currentNote].freq);
      noteEndTick := getTicks + (mel2[currentNote].durationMS div 55)
      end;
    Melody3: begin
      sound(mel3[currentNote].freq);
      noteEndTick := getTicks + (mel3[currentNote].durationMS div 55)
      end;
  end;
end;

procedure TPCSpeaker.init;
begin
  currentNote := -1;
  playing := false;
end;

procedure TPCSpeaker.playMelody(id: SoundIDs);
begin
  if playing then exit;
  currentNote := -1;
  playing := true;
  currentID := id;
  playNextNote
end;

procedure TPCSpeaker.updateMelody;
begin
  if playing and (getTicks >= noteEndTick) then
    playNextNote;
end;


end.
