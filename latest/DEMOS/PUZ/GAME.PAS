{
  Part of Light's Greed game
  By Hevanafa, 04-06-2025
}

uses
  CRT, DOS,
  P92Core, Bitmap, Graphics, Logger, Keyboard, Mouse, Timing, VGA;

var
  { Asset variables }
  DosuEXE: array[0..1] of PBitmap;

  { Game state variables }
  lights: array[0..3] of boolean;
  lastKeys: array[0..2] of boolean;
  t: double;
  allLightsOff: boolean;


procedure OnPreload; far;
begin
  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;

procedure OnCleanup; far;
begin
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);
end;

procedure OnReady; far;
begin
  allLightsOff := false;
  lights[0] := true;
  { lights[1] := true; }
  lights[2] := true;
  lights[3] := true;
end;

procedure UpdateAllLightsOff;
var
  a: word;
begin
  allLightsOff := true;

  for a:=0 to high(lights) do
    if lights[a] then begin
      allLightsOff := false;
      exit
    end;
end;


procedure Update; far;
var
  a: word;
begin
  for a:=0 to high(lastKeys) do begin
    if lastKeys[a] <> isKeyDown(a + SC_1) then begin
      lastKeys[a] := isKeyDown(a + SC_1);

      if lastKeys[a] then
        case a of
        0: begin
          { 1 2 }
          lights[0] := not lights[0];
          lights[1] := not lights[1];
        end;
        1: lights[2] := not lights[2];
        2: begin
          { 2 3 4 }
          lights[1] := not lights[1];
          lights[2] := not lights[2];
          lights[3] := not lights[3];
        end else
        end;

      UpdateAllLightsOff
    end;
  end;

  if isKeyDown(SC_ESCAPE) then SignalDone;

  t:=t+DeltaTime;
end;


procedure Draw; far;
var
  a: word;
begin
  cls($7D);

  for a:=0 to high(lights) do
    if lights[a] then
      circfill(50 + a * 16, 40, 5, 15);

  if allLightsOff then
    print('Good job!', 50, 50, 15);

  if (trunc(t * 1.5) and 1) = 0 then
    Spr(dosuEXE[0], 148, 76, 13)
  else
    Spr(dosuEXE[1], 148, 76, 13);

  print('Press 1, 2, 3, or 4', 160-86, 120, $0F);
  print('to trigger change lights', 160-96, 128, $0F);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.
