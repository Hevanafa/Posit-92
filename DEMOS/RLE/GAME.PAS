{$DEFINE DEBUG}

uses
  CRT, DOS,
  Bitmap, Logger, Keyboard, Mouse, Timing, VGA,
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
  a, b, offset: word;
  count, colour: byte;
begin  
  { writeLn('Hello!'); }
  loadBMP(image, 'IMG/DOSU_1.BMP');

  { PBitmap to TRLEBitmap conversion }
  offset := 0;
  
  count := 0;
  colour := image^.data[0];

  for b:=0 to 15 do begin
    write(b, ': ');

    { for a:=0 to image^.width-1 do begin }
    a := 0;
    while true do begin
      if a >= image^.width then break;

      { offset := b * image^.width + a; }

      if colour = image^.data[offset] then
        inc(count)
      else begin
        { Different pixel in the same scanline }
        write('[', count, ', ', colour, '], ');

        count := 1;
        colour := image^.data[offset];
      end;

      inc(a);
      inc(offset)
    end;

    { Change of scanline }
    writeLn('[', count, ', ', colour, '],');

    { Reset the counter }
    count := 0;
    colour := image^.data[offset];
  end;


  readLn;

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
