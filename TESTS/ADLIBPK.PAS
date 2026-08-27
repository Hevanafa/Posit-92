{
  Percussion kit extension
  Part of Posit-92 game framework
}
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

  TAdLibPercussionDriver = object
    parent: PAdLibDriver;
    procedure enable;
    procedure disable;
    procedure setupKit(const kit: TPercussionKit);
    procedure play(const drums: byte);
    procedure stop;
  end;

var
  AdLibPercussionDrv: TAdLibPercussionDriver;


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

procedure TAdLibPercussionDriver.enable;
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

procedure TAdLibPercussionDriver.disable;
begin
  if not AdLibDrv.getIsInitialised then exit;

  AdLibWrite($BD, $00);
  percussionEnabled := false;
  currentPercMask := 0
end;

procedure TAdLibPercussionDriver.setupKit(const kit: TPercussionKit);
begin
  if not percussionEnabled then exit;

  { Setup bass drum (operators $13 + $16) }
  AdLibWrite($33, $00);  { Modulator }
  AdLibWrite($40 + $13, 63 - kit.bassLevel);  { Modulator level }
  AdLibWrite($43, $00);  { Carrier }
  AdLibWrite($40 + $16, 63 - kit.bassLevel);

  AdLibWrite($60 + $13, $F0);
  AdLibWrite($63, $F0);
  AdLibWrite($80 + $13, $77);
  AdLibWrite($83, $77);

  { Setup snare drum (operator 17) }
  AdLibWrite($31, $00);
  AdLibWrite($40 + $11, 63 - kit.snareLevel);
  AdLibWrite($61, $F8); { very fast attack }
  AdLibWrite($81, $55); { quick decay }

  { Setup tom-tom (operator 15) }
  AdLibWrite($32, $00);
  AdLibWrite($40 + $12, 63 - kit.tomLevel);
  AdLibWrite($62, $F6);
  AdLibWrite($82, $66);

  { Setup cymbal (operator 18) }
  AdLibWrite($35, $01);
  AdLibWrite($40 + $15, 63 - kit.cymbalLevel);
  AdLibWrite($65, $FA);
  AdLibWrite($85, $44);

  { Setup hi-hat (operator 14) }
  AdLibWrite($34, $01);
  AdLibWrite($40 + $14, 63 - kit.hihatLevel);
  AdLibWrite($64, $FC);
  AdLibWrite($84, $33)
end;

procedure TAdLibPercussionDriver.play(const drums: byte);
begin
  if not percussionEnabled then exit;

  { Clear previous percussion }
  AdLibWrite($BD, $20);

  { Set new percussion mask }
  currentPercMask := drums;
  AdLibWrite($BD, $20 or drums)
end;

procedure TAdLibPercussionDriver.stop;
begin
  if not percussionEnabled then exit;

  AdLibWrite($BD, $20);
  currentPercMask := 0
end;

end.
