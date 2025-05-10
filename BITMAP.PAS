unit Bitmap;

interface

type
  PBitmap = ^TBitmap;
  TBitmap = record
    width, height, palsize: word;
    data: array[0..0] of byte;
  end;

procedure loadBMP(var output: PBitmap; filename: string);
procedure drawBMP(image: PBitmap);
procedure freeBMP(var image: PBitmap);
procedure spr(image: PBitmap; x, y: integer; transparencyKey: byte);
procedure bitmapInfo(image: PBitmap);


implementation

uses Logger, Conv, vga;

const DEBUG = false;

{ var makes it pass-by-reference }
procedure loadBMP(var output: PBitmap; filename: string);
var
  f: file;
  buffer: array[1..256] of byte;
  bytesRead: word;
  a, b: integer;
  w, h, palsize, size: integer;
  start, padding: integer;

begin
  assign(f, filename);
  reset(f, 1); { record size is 1 --> binary mode }
  { blockRead(f, buffer, sizeOf(buffer), bytesRead); }
  { writeLn('Read ', bytesRead, ' bytes from sample.bmp'); }
  seek(f, 18); blockRead(f, w, 2);
  seek(f, 22); blockRead(f, h, 2);
  seek(f, 50); blockRead(f, palsize, 2);

  size := sizeOf(TBitmap) + (w * h) - 1;
  getMem(output, size);
  output^.width := w;
  output^.height := h;
  output^.palsize := palsize;
  { output^.size := w * h; }

  if debug then begin
    writeLog('Width:' + i32str(output^.width));
    writeLog('Height:' + i32str(output^.height));
    writeLog('Palette:' + i32str(output^.palsize));
  end;

  start := 54 + palsize * 4;
  if w mod 4 = 0 then
    padding := 0
  else
    padding := 4 - w mod 4;

  if debug then begin
    writeLog('Start:' + i32str(start));
    writeLog('Padding:' + i32str(padding));
  end;

  for b := 0 to h-1 do begin
    seek(f, start + (b * (w + padding)));
    blockRead(f, buffer, w);
    writeLog('Finished reading line ' + i32str(b));

    { for a:=1 to 256 do pset(a-1, h-b-1, buffer[a]); }
    { bottom to top }
    Move(buffer[1], output^.data[(h-b-1) * w], w);
  end;

  close(f);
end;

procedure drawBMP(image: PBitmap);
var
  a, b: integer;
begin
  for b := 0 to image^.height-1 do
  for a := 0 to image^.width-1 do
    pset(a, b, image^.data[a + b * image^.width]);
end;

procedure freeBMP(var image: PBitmap);
begin
  freeMem(image, sizeOf(TBitmap) + (image^.width * image^.height) - 1)
end;

procedure spr(image: PBitmap; x, y: integer; transparencyKey: byte);
var
  a, b, pos: integer;
begin
  for b := 0 to image^.height-1 do
  for a := 0 to image^.width-1 do begin
    pos := a + b * image^.width;
    if image^.data[pos] <> transparencyKey then
      pset(x+a, y+b, image^.data[pos]);
  end;
end;


procedure bitmapInfo(image: PBitmap);
begin
  { print('File name:' + name, 10, 160, 15); }
  print('Width: ' + i32str(image^.width), 10, 168, 15);
  print('Height: ' + i32str(image^.height), 10, 176, 15);
  print('Palette: ' + i32str(image^.palsize) + ' colours', 10, 184, 15)
end;

end.
