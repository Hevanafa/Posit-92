{ Independent AdLibPK Demo }

uses
  CRT,
  AdLib, AdLibPK, Timing;

var
  done: boolean;
  drumKit: TPercussionKit;
  lastUpdate: double;

procedure setupDrumKit;
begin
  drumKit.bassLevel := 20;
  drumKit.snareLevel := 50;
  drumKit.tomLevel := 40;
  drumKit.cymbalLevel := 35;
  drumKit.hihatLevel := 25;
end;


begin
  initDeltaTime;
  AdLibDrv.init;

  setupDrumKit;
  AdLibPercussionDrv.enable;
  AdLibPercussionDrv.setupKit(drumKit);
  lastUpdate := getTimer;

  writeLn('Hello from AdLibPKD!');
  { AdLibPercussionDrv.play(PERC_BASS_BIT); }

  done := false;
  repeat
    updateDeltaTime;

    if keyPressed then begin
      case readKey of
      #27: done := true;
      '1': AdLibPercussionDrv.play(PERC_BASS_BIT);
      '2': AdLibPercussionDrv.play(PERC_SNARE_BIT);
      '3': AdLibPercussionDrv.play(PERC_TOM_BIT);
      '4': AdLibPercussionDrv.play(PERC_CYMBAL_BIT);
      '5': AdLibPercussionDrv.play(PERC_HIHAT_BIT);
      's': AdLibPercussionDrv.stop;
      end;
    end;

    { AdLibDrv.update; }
  until done;

  AdLibPercussionDrv.disable;
  AdLibDrv.shutdown;
end.