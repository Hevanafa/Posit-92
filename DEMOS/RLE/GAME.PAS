{$DEFINE DEBUG}

uses
  CRT, DOS,
  Bitmap, Logger, Keyboard, Mouse,
  Panic, Timing, VGA,
  BMPRLE;

const
  SC_ESC = $01;
var
  done: boolean;
  t: double;
  DosuEXE: array[0..1] of PBitmap;
  { TODO: More of your game state here }


procedure INIT;
begin
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initKeyHandler;
  initMouse;

  { TODO: Your init code here }

  randomize;
  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
end;


procedure update;
begin
  updateDeltaTime;
  updateMouse;

  { TODO: Your update code here }

  if isKeyDown(SC_ESC) then done := true;
  
  t:=t+dt
end;


procedure draw;
begin
  cls($7D);

  { TODO: Your drawing code here }

  if (trunc(t * 1.5) and 1) = 0 then
    asmDrawBMP(dosuEXE[0], 148, 76)
  else
    asmDrawBMP(dosuEXE[1], 148, 76);

  print('Hello world!', 160-48, 120, 15);
  drawMouse;

  flush
end;


var
  startTime: double;
  image: PBitmap;
  sampleRLE: PRLEBitmap;

  { Not yet using longint for prototyping }
  a, x, y: integer;
  readPos, left: integer;
  count, colour: byte;
begin  
  { writeLn('Hello!'); }
  loadBMP(image, 'IMG/DOSU_1.BMP');

  convertToRLE(image, sampleRLE);

  {
  a:=0; x:=0;
  while a < sampleRLE^.dataSize do begin
    count := sampleRLE^.data[a];
    write('[', count, ', ', sampleRLE^.data[a+1], '], ');

    inc(x, count);
    if x >= sampleRLE^.width then begin
      x := 0;
      writeLn;
    end;
    inc(a, 2)
  end;
  }

  readLn;

  initVGAMode;
  initBuffer;

  cls($00);

  { Blit RLE bitmap }
  x := 0; y := 0;
  readPos := 0;
  while readPos < sampleRLE^.dataSize do begin
    count := sampleRLE^.data[readPos];
    colour := sampleRLE^.data[readPos+1];

    { Dangerous: no bounds check }
    for a:=1 to count do
      surface^[y * 320 + x + a - 1] := colour;
    
    inc(x, count);

    if x >= sampleRLE^.width then begin
      x := 0;
      inc(y)
    end;

    inc(readPos, 2);
  end;

  flush;

  readLn;

  initTextMode;

  freeRLEBitmap(sampleRLE);
  freeBMP(image);

  exit;

  INIT;
  done := false;
  startTime := getTimer;

  repeat
    update;
    draw
  until done;

  { TODO: Your cleanup code here }
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);

  resetMouse;
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
