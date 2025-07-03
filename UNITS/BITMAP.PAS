unit Bitmap;

interface

type
  PBitmap = ^TBitmap;
  TBitmap = record
    width, height: word;
    { palsize: word }
    data: array[0..0] of byte;
    { size: longint; }
  end;

procedure loadBMP(var output: PBitmap; const filename: string);

{ Similar to spr but without the transparency check }
procedure drawBMP(const image: PBitmap; const x, y: integer);
procedure pascalDrawBMP(const image: PBitmap; const x, y: integer);
procedure asmDrawBMP(const image: PBitmap; const x, y: integer);

procedure freeBMP(var image: PBitmap);

procedure spr(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
procedure pascalSpr(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
{ Taken from asmSprSafe from SPRTEST demo }
procedure asmSpr(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
procedure asmSprUnsafe(const image: PBitmap; const x, y: integer; const transparencyKey: byte);

procedure sprTint(const image: PBitmap; const x, y: integer; const transparencyKey, tint: byte);
procedure pascalSprTint(const image: PBitmap; const x, y: integer; const transparencyKey, tint: byte);

{ TODO: Implement the version with a TRect }
procedure blitRegion(
  const image: PBitmap;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer;
  const transparencyKey: byte);

procedure bitmapInfo(const image: PBitmap);


implementation

uses
  Logger, Conv, Panic, VGA;

{$IFDEF DEBUG}
const DEBUG_READ_LINES = false;
{$ENDIF}

{ var makes it pass-by-reference }
procedure loadBMP(var output: PBitmap; const filename: string);
var
  f: file;
  buffer: array[1..512] of byte;
  { bytesRead: word; }
  a, b: integer;
  w, h: word;
  palsize, padding: word;
  size, start: longint;

begin
  if output <> nil then
    writeLog('Warning: loadBMP output isn''t nil! Loading "' + filename + '"');
  
  assign(f, filename);
  {$I-} reset(f, 1); {$I+} { record size is 1 --> binary mode }
  if IOResult <> 0 then
    panicHalt('loadBMP: Couldn''t find "' + filename + '"!');

  { blockRead(f, buffer, sizeOf(buffer), bytesRead); }
  { writeLn('Read ', bytesRead, ' bytes from sample.bmp'); }
  seek(f, 18); blockRead(f, w, 2);
  seek(f, 22); blockRead(f, h, 2);
  { seek(f, 50); blockRead(f, palsize, 2); }

  size := sizeOf(TBitmap) + (w * h) - 1;
  getMem(output, size);
  output^.width := w;
  output^.height := h;
  { output^.palsize := palsize; }
  { output^.size := w * h; }

{$IFDEF DEBUG}
  writeLog('Width:' + i32str(output^.width));
  writeLog('Height:' + i32str(output^.height));
  { writeLog('Palette:' + i32str(output^.palsize)); }
{$ENDIF}

  start := 54 + palsize * 4;
  if w mod 4 = 0 then
    padding := 0
  else
    padding := 4 - w mod 4;

{$IFDEF DEBUG}
  writeLog('Start:' + i32str(start));
  writeLog('Padding:' + i32str(padding));
{$ENDIF}

  for b := 0 to h-1 do begin
    seek(f, start + (b * (w + padding)));
    blockRead(f, buffer, w);

{$IFDEF DEBUG}
    if DEBUG_READ_LINES then
      writeLog('Finished reading line ' + i32str(b));
{$ENDIF}

    { for a:=1 to 256 do pset(a-1, h-b-1, buffer[a]); }
    { bottom to top }
    Move(buffer[1], output^.data[(h-b-1) * w], w);
  end;

  close(f)
end;



procedure drawBMP(const image: PBitmap; const x, y: integer);
begin
  asmDrawBMP(image, x, y)
end;

procedure pascalDrawBMP(const image: PBitmap; const x, y: integer);
var
  a, b: integer;
begin
  if image = nil then exit;

  for b := 0 to image^.height-1 do
  for a := 0 to image^.width-1 do
    pset(x + a, y + b, image^.data[a + b * image^.width]);
end;

procedure asmDrawBMP(const image: PBitmap; const x, y: integer);
var
  srcX, srcY, imgWidth, imgHeight: word;
  destX, destY: integer;
  colour: byte;
  imageDataPtr: pointer; { Cache the data pointer }
begin
  destX := x;
  destY := y;
  colour := 0;

  if image = nil then exit;

asm
  les si, image

  { deref imgWidth, make sure it can handle more than 256 bytes width }
  mov ax, word ptr es:[si]  { deref imgWidth }
  mov imgWidth, ax
  add si, 2
  mov ax, word ptr es:[si]  { deref imgHeight }
  mov imgHeight, ax

  add si, 4
  mov word ptr imageDataPtr, si   { store offset }
  mov word ptr imageDataPtr+2, es { store segment }

@y_start:
  mov srcY, 0

@y_condition:
  mov ax, imgHeight
  cmp srcY, ax
  jge @y_end
  
@y_loop:
  { Check bounds }
  mov ax, destY
  add ax, srcY
  cmp ax, 0
  jl @y_next
  cmp ax, 200
  jge @y_end

@x_start:
  mov srcX, 0

@x_condition:
  mov ax, imgWidth
  cmp srcX, ax
  jge @x_end

@x_loop:
  { Check bounds }
  mov ax, destX
  add ax, srcX
  cmp ax, 0
  jl @x_next
  cmp ax, 320
  jge @x_end

  { Get pixel }
  les si, imageDataPtr
  { (srcY * imgWidth) + srcX }
  mov ax, srcY
  mov bx, imgWidth
  mul bx
  add ax, srcX  { ax = b * imgWidth + a }
  add si, ax

  mov al, es:[si]
  mov colour, al

  { Screen destination }
  { (destY + srcY) * 320 + destX + srcX }
  mov ax, destY
  add ax, srcY
  mov bx, 320
  mul bx

  add ax, destX
  add ax, srcX

  { PSET }
  les di, surface  { This replaces both ES & DI with surface's pointer }
  add di, ax
  mov al, colour
  mov es:[di], al

@x_next:
  inc srcX
  jmp @x_condition

@x_end:

@y_next:
  inc srcY
  jmp @y_condition

@y_end:
@skip:
end;

end;


procedure freeBMP(var image: PBitmap);
begin
  if image = nil then exit;
  freeMem(image, sizeOf(TBitmap) + (image^.width * image^.height) - 1);
  image := nil  { avoids dangling pointer }
end;


procedure spr(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
begin
  asmSpr(image, x, y, transparencyKey)
end;

procedure pascalSpr(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
var
  a, b, pos: integer;
begin
  if image = nil then exit;
  for b := 0 to image^.height-1 do
  for a := 0 to image^.width-1 do begin
    pos := a + b * image^.width;
    if image^.data[pos] <> transparencyKey then
      pset(x+a, y+b, image^.data[pos]);
  end;
end;


procedure asmSpr(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
var
  srcX, srcY, imgWidth, imgHeight: word;
  destX, destY: integer;
  colour: byte;
  imageDataPtr: pointer; { Cache the data pointer }
begin
  if image = nil then exit;

  destX := x;
  destY := y;
  imgWidth := image^.width;
  imgHeight := image^.height;
  colour := 0;

{
  writeLog('dest x and y:' + i32str(destX) + ', ' + i32str(destY));
  writeLog('img width & height: ' + i32str(imgWidth) + ', ' + i32str(imgHeight));
  writeLog('transparency key' + i32str(transKey));
}

asm
  les si, image

  add si, 4
  mov word ptr imageDataPtr, si   { store offset }
  mov word ptr imageDataPtr+2, es { store segment }

@y_start:
  mov srcY, 0

@y_condition:
  mov ax, imgHeight
  cmp srcY, ax
  jge @y_end

@y_loop:
  { 135 ops: 0.0867s }
  {
  mov ax, destY
  add ax, srcY
  cmp ax, 0
  jl @y_next
  cmp ax, 200
  jge @y_end
  }

@x_start:
  mov srcX, 0

@x_condition:
  mov ax, imgWidth
  cmp srcX, ax
  jge @x_end

@x_loop:
  { Get pixel }
  { (srcY * imgWidth) + srcX }
  mov ax, srcY
  mov bx, imgWidth
  mul bx
  add ax, srcX  { ax = b * imgWidth + a }

  les si, imageDataPtr
  add si, ax

  { Check if transparent }
  mov al, es:[si]
  cmp al, transparencyKey
  je @x_next

  mov colour, al

  { Check bounds }
  { 135 ops: 0.0547s }
  mov ax, destY
  add ax, srcY
  cmp ax, 0
  jl @y_next
  cmp ax, 200
  jge @y_end

  mov ax, destX
  add ax, srcX
  cmp ax, 0
  jl @x_next
  cmp ax, 320
  jge @x_end

  { Screen dest }
  mov ax, destY
  add ax, srcY
  mov bx, 320
  mul bx

  add ax, destX
  add ax, srcX
  mov bx, ax

  { PSET }
  les di, surface
  add di, bx
  mov al, colour
  mov es:[di], al

@x_next:
  inc srcX
  jmp @x_condition

@x_end:

@y_next:
  inc srcY
  jmp @y_condition

@y_end:
@skip:
end;

end;


{ Based on asmSpr with the difference being not using bounds checks
  Use with caution!
}
procedure asmSprUnsafe(
  const image: PBitmap;
  const x, y: integer;
  const transparencyKey: byte);
var
  srcX, srcY, imgWidth, imgHeight: word;
  destX, destY: integer;
  transKey, colour: byte;
  imageDataPtr: pointer; { Cache the data pointer }
begin
  destX := x;
  destY := y;
  imgWidth := image^.width;
  imgHeight := image^.height;
  transKey := transparencyKey;
  colour := 0;

asm
  les di, [image]

  { Check if image is nil }
  mov ax, es
  or ax, di
  je @skip

  add di, 4
  mov word ptr imageDataPtr, di   { store offset }
  mov word ptr imageDataPtr+2, es { store segment }

@y_start:
  mov srcY, 0

@y_condition:
  mov ax, imgHeight
  cmp srcY, ax
  jge @y_end

@y_loop:

@x_start:
  mov srcX, 0

@x_condition:
  mov ax, imgWidth
  cmp srcX, ax
  jge @x_end

@x_loop:
  { Get pixel }
  { Obtain the `data` offset }
  mov ax, srcY
  mov bx, imgWidth
  mul bx
  add ax, srcX  { ax = b * imgWidth + a }

  les di, imageDataPtr
  add di, ax

  { Check if transparent }
  mov al, es:[di]
  cmp al, transKey
  je @x_next

  mov colour, al

  { Screen dest }
  mov bx, destY
  add bx, srcY
  mov cx, 320
  mov ax, bx
  mul cx

  add ax, destX
  add ax, srcX
  mov bx, ax

  { PSET }
  push es
  les di, surface
  mov al, colour
  mov es:[di+bx], al
  pop es


@x_next:
  inc srcX
  jmp @x_condition

@x_end:

@y_next:
  inc srcY
  jmp @y_condition

@y_end:
@skip:
end;

end;


{
  Tint a sprite
  Recommended to use a monochrome bitmap
  Currently doesn't have the assembly equivalent
}
procedure sprTint(const image: PBitmap; const x, y: integer; const transparencyKey, tint: byte);
begin
  pascalSprTint(image, x, y, transparencyKey, tint)
end;

procedure pascalSprTint(const image: PBitmap; const x, y: integer; const transparencyKey, tint: byte);
var
  a, b, pos: integer;
begin
  if image = nil then exit;
  for b := 0 to image^.height-1 do
  for a := 0 to image^.width-1 do begin
    pos := a + b * image^.width;
    if image^.data[pos] <> transparencyKey then
      pset(x+a, y+b, tint);
  end;
end;

{ Improved version of spr with partial sprite drawing }
procedure blitRegion(
  const image: PBitmap;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer;
  const transparencyKey: byte);
var
  a, b, pos: integer;
begin
  if image = nil then exit;
  
  for b := 0 to srcH - 1 do
  for a := 0 to srcW - 1 do begin
    pos := (srcX + a) + ((srcY + b) * image^.width);
    if image^.data[pos] <> transparencyKey then
      pset(destX + a, destY + b, image^.data[pos]);
  end;
end;


procedure bitmapInfo(const image: PBitmap);
begin
  if image = nil then begin
    print('image is nil!', 10, 168, 15);
    exit
  end;

  { print('File name:' + name, 10, 160, 15); }
  print('Width: ' + i32str(image^.width), 10, 168, 15);
  print('Height: ' + i32str(image^.height), 10, 176, 15);
  { print('Palette: ' + i32str(image^.palsize) + ' colours', 10, 184, 15) }
end;


end.
