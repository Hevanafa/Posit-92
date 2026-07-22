{$DEFINE DEBUG}

uses
  CRT, DOS,
  Conv, Graphics, Logger, Timing, VGA;

const
  SC_ESC = $01;
var
  done: boolean;
  t: double;
  { DosuEXE: array[0..1] of PBitmap; }
  { TODO: More of your game state here }


procedure INIT;
begin
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;

  { TODO: Your init code here }

  randomize;
  {
  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
  }
end;


procedure update;
begin
  updateDeltaTime;

  { TODO: Your update code here }

  if keyPressed then if readKey = #27 then done := true;
  
  t:=t+dt
end;


procedure drawCredits;
begin
  asmCls($7D);

  { TODO: Your drawing code here }

  {
  if (trunc(t * 1.5) and 1) = 0 then
    asmSpr(dosuEXE[0], 148, 76, 13)
  else
    asmSpr(dosuEXE[1], 148, 76, 13);
  }

  print('BugTracker PRO v2.1', 8, 8, 15);

  print('A short game by Hevanafa', 8, 24, 15);
  print('for the', 8, 32, 15);
  print('Monochromatic Game Jam 1', 8, 40, 15);
  print('on itch.io', 8, 48, 15);
  print('in June 2025', 8, 56, 15);

  print('Final efficiency rating: CLASSIFIED', 8, 72, 15);

  print('Thank you for using BugTracker PRO', 8, 88, 15);

  print('WARNING: This software may cause', 8, 104, 15);
  print('uncontrolled productivity increases', 8, 112, 15);

  print('[ESC] Exit to DOS', 8, 128, 15);

  asmFlush
end;


var
  a: word;
  startTime, diff: double;
begin
  INIT;
  done := false;

  {
  repeat
    update;
    draw
  until done;
  }

  asmCls($00);

  startTime := getTimer;
  {
  for a:=1 to 1000 do
    hline(0, 319, a mod 200, 15);

  diff := getTimer - startTime;
  asmPrint('1000 operations done in ' + f32str(diff) + 's', 0, 0, 7);
  }

  { asmHline(0, 319, 100, 15); }

  {
  for a:=1 to 1000 do
    asmHline(0, 319, a mod 200, 15);

  diff := getTimer - startTime;
  asmPrint('1000 operations done in ' + f32str(diff) + 's', 0, 0, 7);
  }

  { 100 operations with hline: 7.0612s }
  { 100 operations with asmHline: 3.4260s }
  { 1000 operations: DNF }
  {
  for a:=1 to 100 do
    rectfill(0, 0, 320, 200, 15);

  diff := getTimer - startTime;
  asmPrint('100 operations done in ' + f32str(diff) + 's', 0, 0, 7);
  }

  { 1 operation: 0.0900s }
  { 100 operations: 7.0611s }
  { for a:=1 to 100 do }
  { rectfill(0, 0, 320, 200, 15); }

  { 1 operation (full assembly): 0.0131s }
  { 100 operations (full assembly): 3.3985s }
  for a:=1 to 100 do
    asmRectfill(0, 0, 320, 200, 15);

  diff := getTimer - startTime;
  asmPrint('100 operations done in ' + f32str(diff) + 's', 0, 0, 7);

  asmFlush;

  readLn;

  { TODO: Your cleanup code here }
  {
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);
  }

  freeBuffer;
  closeLogger;
  initTextMode
end.
