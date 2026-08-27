uses CRT, Sound;

const
  C = 0;
  E = 4;
  G = 7;
  C2 = 12;

var
  a: integer;
  AdLib: TAdLib;
begin
  adlib.init;

  { adlib.noteOn(0, 32); delay(1000); }
  adlib.setPercussive(true);

  { Bass drum }
  adlib.noteOn(6, 60);
  delay(500);
  adlib.noteOff(6, 60);
{
  for a:=1 to 3 do begin
    adlib.noteOn(6, 60);
    delay(500);
    adlib.noteOff(6, 60);
  end;
}

  { Snare drum }
  adlib.noteOn(7, 40);
  delay(500);
  adlib.noteOff(7, 40);

  { Tom-tom }
  {
  adlib.noteOn(8, 40);
  delay(500);
  adlib.noteOff(8, 40);
  }

  { Cymbal }
  adlib.noteOn(9, 40);
  delay(500);
  adlib.noteOff(9, 40);

  { Hi-hat }
  {
  adlib.noteOn(10, 40);
  delay(500);
  adlib.noteOff(10, 40);
  }


  for a:=$01 to $F5 do
    sndOutput(a, 0);

  readLn;

end.