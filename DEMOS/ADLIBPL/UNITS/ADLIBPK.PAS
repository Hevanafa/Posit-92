{
  Percussion kit extension
  Part of Posit-92 game framework
}
unit AdLibPK;

interface

uses AdLib;

const
  PERC_BASS_BIT = $10;
  PERC_SNARE_BIT = $08;
  PERC_HIHAT_BIT = $01;
  PERC_TOM_BIT = $04;
  PERC_CYMBAL_BIT = $02;

type
  TPercussionKit = record
    bassLevel,
    snareLevel,
    tomLevel,
    cymbalLevel,
    hihatLevel: byte
  end;

  TAdLibPercussionDriver = object
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
  PERC_SNARE = 7;
  PERC_HIHAT = 7;
  PERC_TOM = 8;
  PERC_CYMBAL = 8;

var
  percussionEnabled: boolean;
  currentPercMask: byte;

procedure TAdLibPercussionDriver.enable;
begin
  if not AdLibDrv.getIsInitialised then exit;
  
  { Enable rhythm mode in register $BD }
  AdLibWrite($BD, $00);

  { Setup default percussion frequencies }
  AdLibWrite($A6, $16);
  AdLibWrite($B6, $20);

  { Snare on channel 7 }
  AdLibWrite($A7, $16);
  AdLibWrite($B7, $20);

  { Tom on channel 8 }
  AdLibWrite($A8, $16);
  AdLibWrite($b8, $20);

  AdLibWrite($BD, $20);
  percussionEnabled := true;
  currentPercMask := 0;

  writeLn('Enabled TAdLibPercussionDriver')
end;

procedure TAdLibPercussionDriver.disable;
begin
  if not AdLibDrv.getIsInitialised then exit;

  AdLibWrite($BD, $00);
  percussionEnabled := false;
  currentPercMask := 0;

  writeLn('Disabled TAdLibPercussionDriver')
end;

procedure TAdLibPercussionDriver.setupKit(const kit: TPercussionKit);
begin
  if not percussionEnabled then exit;

  { Setup bass drum (operators 12 + 15) }
  AdLibWrite($20 + $0C, $01);  { Modulator }
  AdLibWrite($40 + $0C, 63 - kit.bassLevel);  { Modulator level }
  AdLibWrite($60 + $0C, $F0);  { fast attack }
  AdLibWrite($80 + $0C, $77);  { medium delay }

  AdLibWrite($20 + $0F, $01);
  AdLibWrite($40 + $0F, 63 - kit.bassLevel);
  AdLibWrite($60 + $0F, $F0);
  AdLibWrite($80 + $0F, $77);

  { Setup snare drum (operator 16) }
  AdLibWrite($20 + $10, $01);
  AdLibWrite($40 + $10, 63 - kit.snareLevel);
  AdLibWrite($60 + $10, $F8); { very fast attack }
  AdLibWrite($80 + $10, $55); { quick decay }

  { Setup tom-tom (operator 14) }
  AdLibWrite($20 + $0E, $01);
  AdLibWrite($40 + $0E, 63 - kit.tomLevel);
  AdLibWrite($60 + $0E, $F6);
  AdLibWrite($80 + $0E, $66);

  { Setup cymbal (operator 17) }
  AdLibWrite($20 + $11, $01);
  AdLibWrite($40 + $11, 63 - kit.cymbalLevel);
  AdLibWrite($60 + $11, $FA);
  AdLibWrite($80 + $11, $44);

  { Setup hi-hat (operator 13) }
  AdLibWrite($20 + $0D, $01);
  AdLibWrite($40 + $0D, 63 - kit.hihatLevel);
  AdLibWrite($60 + $0D, $FC);
  AdLibWrite($80 + $0D, $33)
end;

procedure TAdLibPercussionDriver.play(const drums: byte);
begin
  if not percussionEnabled then exit;

  writeLn('Playing ', drums);

  { Clear previous percussions }
  AdLibWrite($BD, $20);

  { Simulate delay }
asm
  mov cx, 100
  @delay:
  loop @delay
end;

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

{ TODO: Combine percussions function }

end.
