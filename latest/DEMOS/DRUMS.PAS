uses CRT, DOS;

const
  AdLibAddr = $388;
  AdLibData = $389;

procedure OutAdLib(reg, value: byte);
var
  i: byte;
begin
  Port[AdLibAddr] := reg;
  for i := 1 to 6 do ; { 6x read = 3.3 µs delay }
  Port[AdLibData] := value;
  for i := 1 to 35 do ; { 35x read = 23 µs delay }
end;

procedure SetupRhythmMode;
begin
  { Enable waveforms }
  OutAdLib($01, $20);

  { Set bass drum (channel 6 = operators 12, 15) }
  OutAdLib($20 + $10, $01);  { Modulator multiple }
  OutAdLib($23 + $10, $01);  { Carrier multiple }
  OutAdLib($40 + $10, $10);  { Modulator volume }
  OutAdLib($43 + $10, $00);  { Carrier volume }
  OutAdLib($60 + $10, $F0);  { Mod attack/decay }
  OutAdLib($63 + $10, $F0);  { Car attack/decay }
  OutAdLib($80 + $10, $77);  { Mod sustain/release }
  OutAdLib($83 + $10, $77);  { Car sustain/release }

  { Turn off melodic voices 6–8 }
  OutAdLib($B6, 0);
  OutAdLib($B7, 0);
  OutAdLib($B8, 0);

  { Enable rhythm mode (bit 5) only, no drums yet }
  OutAdLib($BD, $20);
end;

procedure PlayBassDrum;
begin
  { Enable rhythm mode + bass drum bit (bit 4) }
  OutAdLib($BD, $30);  { $20 (rhythm) + $10 (bass drum) }
  Delay(100);
  OutAdLib($BD, $20);  { Turn bass drum off, keep rhythm mode }
end;

procedure PlayAllDrums;
begin
  { All percussion bits on: $3F = %00111111 }
  OutAdLib($BD, $3F);
  Delay(200);
  OutAdLib($BD, $20);  { Turn all drums off }
end;

begin
  SetupRhythmMode;
  WriteLn('Playing Bass Drum...');
  PlayBassDrum;
  readLn;
end.

