
uses
  CRT, DOS,
  P92Core, Bitmap, Conv, Graphics, Logger, Mouse, Timing, VGA;

var
  { Asset variables }
  DosuEXE: array[0..1] of PBitmap;

  { Game state variables }
  t: double;


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


var
  a, x, y: integer;
  startTime: double;
begin
  OnPreload;

  cls($7D);
  startTime := getTimer;

  {
  for a:=0 to 1000 do
    spr(dosuEXE[0], random(300), random(180), 13);
  }

  { for a:=1 to 1000 do begin
    x := random(300);
    y := random(180); }

    { TODO: This only works once }
    { fastSpr4(dosuEXE[0], x, y, 13); }
    { fastSpr5(dosuEXE[0], x, y, 13); }
    { print(i32str(a), x, y, 15); }
  { end; }

  { fastSpr5(dosuEXE[0], 100, 50, 13);
  fastSpr5(dosuEXE[0], 150, 50, 13); }

  {fastSpr6(dosuEXE[0], 150, 50, 13);}

  {
  spr(dosuEXE[0], 150, 50, 13);
  }

  { asmSprUnsafe(dosuEXE[0], 150, 50, 13); }
  for a:=1 to 1000 do begin
    x := random(300);
    y := random(180);
    { spr(dosuEXE[0], x, y, 13); }  { pset_legacy:1.3392s, pset: 1.3095s }
    asmSprSafe(dosuEXE[0], x, y, 13);  { 0.6819s, 0.6826s }
  end;

  { Black rectangle behind the text below }
  rectfill(0, 0, 240, 8, 0);
  print('1000 operations done in ' + f32str(getTimer - startTime) + 's', 0, 0, 15);

  flush;
  readLn;
end.
