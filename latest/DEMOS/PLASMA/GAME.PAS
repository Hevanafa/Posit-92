{
  Plasma demo
  17-05-2025
  Part of Posit-92 demos
  Author: Hevanafa
}

uses
  CRT, DOS,
  P92Core, Logger,
  P92KBD, P92Mouse,
  Timing, P92VGA, Bitmap, FPS;

var
  { Game state variables }
  sinTable: array[0..255] of integer;
  startTime, t: double;

procedure buildSinTable;
var
  a: integer;
begin
  for a:=0 to 255 do
    sinTable[a] := round(128 + 127 * sin(a*2*pi/256))
end;


procedure OnReady; far;
begin
  startTime := getTimer;
  buildSinTable
end;

procedure Update; far;
begin
  if isKeyDown(SC_ESCAPE) then SignalDone;

  t := getTimer - startTime
end;


procedure Draw; far;
const
  step = 2;
var
  a, b, c, d: integer;
  aIndex, bIndex: integer;
  ta, tb: integer;
  colour: byte;
begin
  ta := round(t) mod 256;
  tb := round(t * 2) mod 256;

  b := 0;
  while b <= 199 do begin
    bIndex := (b + tb) and 255;

    a := 0;
    while a <= 319 do begin
      aIndex := (a + ta) and 255;
      colour := sinTable[aIndex] + sinTable[bIndex];
      colour := 104 + (colour shr 2);

      { `surface` is pulled out from the implementation section }
      surface^[b*320 + a] := colour;
      surface^[b*320 + a+1] := colour;
      surface^[(b+1)*320 + a] := colour;
      surface^[(b+1)*320 + a+1] := colour;

      inc(a, step)
    end;
    inc(b, step)
  end;
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;

  P92Start(appConfig)
end.

