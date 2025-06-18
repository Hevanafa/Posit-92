{ Percussion kit extension }
unit AdLibPK;

interface

var
  AdLibPercussionDrv: TAdLibPercussion


implementation

uses AdLib;

const
  PERC_BASS_DRUM = 6;
  PERC_BASS_BIT = $10;
  PERC_SNARE = 7;
  PERC_SNARE_BIT = $08;
  PERC_HIHAT = 7;
  PERC_HIHAT_BIT = $01;
  PERC_TOM = 8;
  PERC_TOM_BIT = $04;
  PERC_CYMBAL = 8;
  PERC_CYMBAL_BIT = $02;

type
  TPercussionKit = record
    bassLevel,
    snareLevel,
    tomLevel,
    cymbalLevel,
    hihatLevel: byte
  end;

  TAdLibPercussion = object
    procedure enable;
    procedure disable;
    procedure setupKit(const kit: TPercussionKit);
    procedure play(const drums: byte);
    procedure stop;
  end;
  
end.
