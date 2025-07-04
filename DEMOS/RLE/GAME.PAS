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


procedure convertToRLE(const src: PBitmap; var output: PRLEBitmap);
var
  a, b, offset: word;
  count, colour: byte;
  writePos: word;
begin
  if src = nil then panicHalt('convertToRLE: src is nil!');

  { PBitmap to TRLEBitmap conversion }

  { Pass 1 }
  writePos := 0;
  offset := 0;

  count := 0;
  colour := src^.data[0];

  for b:=0 to src^.height-1 do begin
    { write(b, ': '); }

    { for a:=0 to src^.width-1 do begin }
    a := 0;
    while true do begin
      if a >= src^.width then break;

      { offset := b * src^.width + a; }

      if colour = src^.data[offset] then
        inc(count)
      else begin
        { Different pixel in the same scanline }
        { write('[', count, ', ', colour, '], '); }
        inc(writePos, 2);

        count := 1;
        colour := src^.data[offset];
      end;

      inc(a);
      inc(offset)
    end;

    { Change of scanline }
    { writeLn('[', count, ', ', colour, '],'); }
    inc(writePos, 2);

    { Reset the counter }
    count := 0;
    { Note: This doesn't handle offset overflow }
    colour := src^.data[offset];
  end;

  writeLn('Pass 1 writePos: ', writePos);

  getMem(output, sizeof(TRLEBitmap) + writePos);
  output^.width := src^.width;
  output^.height := src^.height;
  output^.dataSize := writePos;


  { Pass 2 }
  writePos := 0;
  offset := 0;

  count := 0;
  colour := src^.data[0];

  for b:=0 to src^.height-1 do begin
    a := 0;
    while true do begin
      if a >= src^.width then break;

      if colour = src^.data[offset] then
        inc(count)
      else begin
        { Different pixel in the same scanline }
        output^.data[writePos] := count;
        output^.data[writePos+1] := colour;
        inc(writePos, 2);

        count := 1;
        colour := src^.data[offset];
      end;

      inc(a);
      inc(offset)
    end;

    { Change of scanline }
    output^.data[writePos] := count;
    output^.data[writePos+1] := colour;
    inc(writePos, 2);

    { Reset the counter }
    count := 0;
    colour := src^.data[offset];
  end;

  writeLn('Pass 2 writePos: ', writePos);
end;


procedure freeRLEBitmap(var image: PRLEBitmap);
begin
  if image = nil then exit;
  freeMem(image, sizeof(TRLEBitmap) + image^.dataSize);
  image := nil
end;


var
  startTime: double;
  image: PBitmap;
  sampleRLE: PRLEBitmap;
begin  
  { writeLn('Hello!'); }
  loadBMP(image, 'IMG/DOSU_1.BMP');

  convertToRLE(image, sampleRLE);

  readLn;

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
