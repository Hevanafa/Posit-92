{ Percussion kit extension }
unit AdLibPK;

interface

uses AdLib;

type
  TPercussionKit = record
    bassLevel,
    snareLevel,
    tomLevel,
    cymbalLevel,
    hihatLevel: byte
  end;

  TAdLibPercussion = object
    parent: PAdLibDriver;
    procedure enable;
    procedure disable;
    procedure setupKit(const kit: TPercussionKit);
    procedure play(const drums: byte);
    procedure stop;
  end;

var
  AdLibPercussionDrv: TAdLibPercussion;


implementation

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


var
  percussionEnabled: boolean;
  currentPercMask: byte;

procedure TAdLibPercussion.enable;
begin
  if not AdLibDrv.getIsInitialised then exit;
  
  { Enable rhythm mode in register $BD }
  AdLibWrite($BD, $20);
  percussionEnabled := true;
  currentPercMask := 0;

  { Setup default percussion frequencies }
  AdLibWrite($A6, $15);
  AdLibWrite($B6, $28);

  { Snare on channel 7 }
  AdLibWrite($A7, $12);
  AdLibWrite($B7, $25);

  { Tom on channel 8 }
  AdLibWrite($A8, $0C);
  AdLibWrite($b8, $22);
end;

procedure TAdLibPercussion.disable;
begin
  if not AdLibData.getIsInitialised then exit;

  AdLibWrite($BD, $00);
  percussionEnabled := false;
  currentPercMask := 0
end;

end.
