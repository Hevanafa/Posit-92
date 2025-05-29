unit Bitmap;

interface

type
  PBitmap = ^TBitmap;
  TBitmap = record
    width, height, palsize: word;
    data: array[0..0] of byte;
  end;

procedure loadBMP(var output: PBitmap; const filename: string);
procedure drawBMP(const image: PBitmap);
procedure freeBMP(var image: PBitmap);
procedure spr(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
{ procedure fastSpr(const image: PBitmap; const x, y: integer; const transparencyKey: byte); }
procedure fastSpr2(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
procedure fastSpr3(const image: PBitmap; const x, y: integer; const transparencyKey: byte);

{ Use this for UI elements in general }
{ procedure fastSprUnsafe(const image: PBitmap; const x, y: integer; const transparencyKey: byte); }
procedure fastSpr4(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
procedure fastSpr5(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
procedure fastSprUnsafe(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
procedure asmSpr(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
procedure asmSprUnsafe(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
procedure asmSprSafe(const image: PBitmap; const x, y: integer; const transparencyKey: byte);

procedure sprTint(const image: PBitmap; const x, y: integer; const transparencyKey, tint: byte);
procedure spr2(
  const image: PBitmap;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer;
  const transparencyKey: byte);
procedure initTrigLUT;
procedure sprPro(const image: PBitmap; const x, y: integer; angle: double; const transparencyKey: byte); { in degrees }
procedure sprPro2(
  const image: PBitmap;
  const x, y: integer;
  const scaleX, scaleY: double;
  angle: double;
  const transparencyKey: byte);
{ procedure sprProLUT(image: PBitmap; x, y: integer; scaleX, scaleY, angle: double; transparencyKey: byte); }
procedure sprProLUT(
  const image: PBitmap;
  const x, y: integer;
  const scaleX, scaleY: double;
  const angle10: integer;
  const transparencyKey: byte);
procedure bitmapInfo(const image: PBitmap);


implementation

uses Logger, Conv, Panic, VGA;

const DEBUG = true;

var
  sinLUT, cosLUT: array[0..35] of double;

{ var makes it pass-by-reference }
procedure loadBMP(var output: PBitmap; const filename: string);
var
  f: file;
  buffer: array[1..256] of byte;
  bytesRead: word;
  a, b: integer;
  w, h, palsize, size: integer;
  start, padding: integer;

begin
  assign(f, filename);
  {$I-} reset(f, 1); {$I+} { record size is 1 --> binary mode }
  if IOResult <> 0 then
    panicHalt('loadBMP: Couldn''t find "' + filename + '"!');

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

    if debug then
      writeLog('Finished reading line ' + i32str(b));

    { for a:=1 to 256 do pset(a-1, h-b-1, buffer[a]); }
    { bottom to top }
    Move(buffer[1], output^.data[(h-b-1) * w], w);
  end;

  close(f)
end;

procedure drawBMP(const image: PBitmap);
var
  a, b: integer;
begin
  if image = nil then exit;
  for b := 0 to image^.height-1 do
  for a := 0 to image^.width-1 do
    pset(a, b, image^.data[a + b * image^.width]);
end;

procedure freeBMP(var image: PBitmap);
begin
  if image = nil then exit;
  freeMem(image, sizeOf(TBitmap) + (image^.width * image^.height) - 1);
  image := nil  { avoids dangling pointer }
end;

procedure spr(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
var
  a, b, pos: integer;
begin
  if image = nil then exit;
  for b := 0 to image^.height-1 do
  for a := 0 to image^.width-1 do begin
    pos := a + b * image^.width;
    if image^.data[pos] <> transparencyKey then
      pset(x+a, y+b, image^.data[pos]);  { 1000 ops: 1.1959s }
      { pset_legacy(x+a, y+b, image^.data[pos]); } { 1000 ops: 1.2320s }
  end;
end;

procedure fastSpr(const image: PBitmap; const x, y: integer; const transparencyKey: byte); assembler;
asm
  les di, image
  mov ax, es
  or ax, di
  jz @@done  { Exit if image = nil }

  { Load image dimensions }
  mov cx, es:[di].TBitmap.width
  mov dx, es:[di].TBitmap.height

  { Calculate pointer to image data }
  add di, OFFSET TBitmap.data

  { Set up source pointer to image data }
  push ds
  push es
  pop ds
  mov si, di

  { Setup destination pointer -- ES:DI will point to surface }
  les di, surface

  mov ax, y
  cmp ax, 200  { Check if y is out of bounds }
  jae @@cleanup

  mov bx, 320
  mul bx  { DX:AX = y * 320 }

  mov bx, x
  cmp bx, 320  { Check if x is out of bounds }
  jae @@cleanup

  add ax, bx  { AX = y * 320 + x }
  add di, ax  { DI = surface + (y * 320 + x) }

  { Setup for drawing }
  { This causes Error 155: Invalid combination of opcode and operands }
  { mov bx, transparencyKey }  { BX = transparent colour }
  mov bh, 0
  mov bl, [bp+6] { get transparencyKey parameter from stack }

  mov ax, 320
  sub ax, cx  { AX = stride adjustment (320 - width) }

  { Outer loop - height }
  xor ax, ax  { Clear AX for row counter }

@@yloop:
  push cx
  push di

  { Inner loop - width }
@@xloop:
  lodsb  { AL = [DS:SI], SI++ }
  cmp al, bl
  je @@skip  { Skip if transparent }

  { Write pixel to destination }
  mov es:[di], al

@@skip:
  inc di
  dec cx
  jnz @@xloop

  pop di
  add di, 320

  pop cx
  inc ax
  cmp ax, dx
  jb @@yloop

@@cleanup:
  pop ds  { restore DS }

@@done:
end;


{ Simpler version with cleaner bounds checking }
procedure fastSpr2(const image: PBitmap; const x, y: integer; const transparencyKey: byte); assembler;
asm
  push ds
  push bp             { save BP so we can use it }
  
  { Check if image is nil }
  lds si, image
  mov ax, ds
  or ax, si
  jz @@done
  
  { Load dimensions }
  mov cx, [si]        { width }
  mov bx, [si+2]      { height }
  add si, 6           { skip to data }
  
  { Save dimensions }
  push bx             { save height }
  push cx             { save width }
  
  { Load surface pointer into ES }
  les di, surface
  
  { Initialize row counter }
  xor dx, dx          { dx = current row (0) }
  
@@row_loop:
  { Check if we've drawn all rows }
  mov bp, sp
  mov bx, [bp+2]      { bx = height (from stack) }
  cmp dx, bx
  jae @@finish
  
  { Initialize column counter }
  xor cx, cx          { cx = current column (0) }
  
@@col_loop:
  { Get width from stack }
  mov bp, sp
  mov bx, [bp]        { bx = width (from stack) }
  cmp cx, bx
  jae @@next_row
  
  { Get pixel }
  lodsb               { al = pixel value }
  cmp al, transparencyKey
  je @@skip_pixel
  
  { Calculate screen position }
  push dx             { save row }
  push cx             { save column }
  push si             { save image pointer }
  
  { screenY = y + row }
  mov bx, y
  add bx, dx
  
  { Check Y bounds }
  cmp bx, 200
  jae @@skip_draw
  
  { screenX = x + column }
  mov dx, x
  add dx, cx
  
  { Check X bounds }
  cmp dx, 320
  jae @@skip_draw
  
  { Calculate offset: bx * 320 + dx }
  mov ax, bx
  mov cx, 320
  mul cx              { ax = y * 320 }
  add ax, dx          { ax = y * 320 + x }
  mov bx, ax
  
  { Write pixel }
  mov es:[bx], al
  
@@skip_draw:
  pop si              { restore image pointer }
  pop cx              { restore column }
  pop dx              { restore row }
  
@@skip_pixel:
  inc cx              { next column }
  jmp @@col_loop
  
@@next_row:
  { Restore width for next row }
  mov bp, sp
  mov cx, [bp]        { cx = width }
  
  { Adjust source pointer to start of next row }
  { (in case some pixels were transparent) }
  sub si, cx          { back to start of current row }
  add si, cx          { forward to next row }
  
  inc dx              { next row }
  jmp @@row_loop
  
@@finish:
  pop cx              { clean up width }
  pop bx              { clean up height }
  
@@done:
  pop bp              { restore BP }
  pop ds
end;


procedure fastSpr3(const image: PBitmap; const x, y: integer; const transparencyKey: byte); assembler;
asm
  push ds
  
  { Check if image is nil }
  lds si, image
  mov ax, ds
  or ax, si
  jz @@done
  
  { Get dimensions and save them }
  mov ax, [si]        { width }
  mov dx, [si+2]      { height }
  push ax             { save width }
  push dx             { save height }
  add si, 6           { point to image data }
  
  { Outer loop for rows }
  mov dx, 0           { row counter }
  
@@row_loop:
  pop bx              { get height }
  push bx             { put it back }
  cmp dx, bx
  jae @@finish        { done if row >= height }
  
  { Inner loop for columns }
  mov cx, 0           { column counter }
  
@@col_loop:
  mov bx, sp
  mov ax, ss:[bx+2]   { get width from stack }
  cmp cx, ax
  jae @@next_row      { done with row if col >= width }
  
  { Get pixel }
  mov al, [si]
  inc si
  
  { Check transparency }
  cmp al, transparencyKey
  je @@transparent
  
  { Calculate destination position }
  push cx             { save registers }
  push dx
  push si
  
  { screenY = y + row }
  mov bx, y
  add bx, dx
  
  { Check Y bounds }
  cmp bx, 200
  jae @@skip_pixel
  
  { screenX = x + col }
  mov dx, x
  add dx, cx
  
  { Check X bounds }  
  cmp dx, 320
  jae @@skip_pixel
  
  { Calculate offset = bx * 320 + dx }
  mov ax, bx
  mov cx, 320
  mul cx
  add ax, dx
  mov bx, ax
  
  { Write pixel }
  push es
  les di, surface
  mov es:[bx], al
  pop es
  
@@skip_pixel:
  pop si
  pop dx
  pop cx
  
@@transparent:
  inc cx
  jmp @@col_loop
  
@@next_row:
  inc dx
  jmp @@row_loop
  
@@finish:
  pop dx              { clean stack }
  pop ax
  
@@done:
  pop ds
end;


{ This version works, but doesn't check bounds }
procedure fastSprUnsafe(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
var
  screenOffset: word;
  imgSeg, imgOfs: word;
  imgWidth, imgHeight: word;
  trans: byte;
  i: word;
begin
  if image = nil then exit;

  screenOffset := y * 320 + x;
  imgSeg := seg(image^);
  imgOfs := ofs(image^);
  imgWidth := image^.width;
  imgHeight := image^.height;
  trans := transparencyKey;

  asm
    push ds
    les di, surface         { ES:DI = surface^ (backbuffer at 0:A000) }

    mov ax, imgSeg
    mov ds, ax              { DS = segment of image^ }
    mov si, imgOfs
    add si, 6               { DS:SI = start of image^.data }

    mov cx, imgHeight       { outer loop: height }
    { mov bx, imgWidth }        { store width in BX }
    mov dx, screenOffset    { starting screen offset }

    mov ah, trans { store key in BP (low byte used) }

@rowLoop:
    push cx                 { save row count }
    push dx                 { save screen offset }

    mov cx, imgWidth              { CX = width }
    mov bx, dx

@colLoop:
    lodsb                   { AL = [DS:SI], SI++ }
    cmp al, ah              { compare AL with transparency key (BP) }
    je @skip

    mov [es:di+bx], al      { draw pixel }

@skip:
    inc bx
    loop @colLoop

    pop dx
    add dx, 320             { move down one row }
    pop cx
    loop @rowLoop

    pop ds
  end;
end;


{ This version works, but only once }
procedure fastSpr4(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
var
  screenBase: word;
  imgSeg, imgOfs: word;
  imgWidth, imgHeight: word;
  trans: byte;
begin
  if image = nil then exit;

  imgSeg := seg(image^);
  imgOfs := ofs(image^);
  imgWidth := image^.width;
  imgHeight := image^.height;
  trans := transparencyKey;

  asm
    push ds
    push bp
    mov bp, sp

    { Access x and y from stack: x = [bp+8], y = [bp+6] }

    { x clipping }
    mov ax, [bp+8]     { x }
    cmp ax, 0
    jl @skipDrawing
    cmp ax, 320
    jge @skipDrawing

    { y clipping }
    mov ax, [bp+6]     { y }
    cmp ax, 0
    jl @skipDrawing
    cmp ax, 200
    jge @skipDrawing

    { Now compute screenBase = y * 320 + x }
    mov ax, [bp+6]     { y }
    mov cx, 320
    mul cx             { dx:ax = y*320 → ax = low word }
    add ax, [bp+8]     { + x }
    mov screenBase, ax

    pop bp

    { Begin blitter }

    les di, surface
    mov ax, imgSeg
    mov ds, ax
    mov si, imgOfs
    add si, 6               { skip width/height }

    mov cx, imgHeight
    mov dx, screenBase
    mov ah, trans

@rowLoop:
    push cx
    push dx
    mov cx, imgWidth
    mov bx, dx

@colLoop:
    lodsb
    cmp al, ah
    je @skip
    mov es:[di+bx], al
@skip:
    inc bx
    loop @colLoop

    pop dx
    add dx, 320
    pop cx
    loop @rowLoop

@skipDrawing:
    pop ds
  end;
end;


{ This version works but only once }
procedure fastSpr5(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
var
  trans: byte;
begin
  if image = nil then exit;

  {
    Stack entries (bp+N):
    0: return address
    2: saved bp
    4: image ptr: ofs
    6: image ptr: seg
    8: x
    10: y
    12: transparency key
  }

  asm
    push bp
    mov bp, sp
    push ds  { Save DS }

    { Access x and y from stack: x = [bp+8], y = [bp+6] }
    { Load parameters }

    mov si, [bp+4]
    mov ax, [bp+6]
    mov ds, ax
    mov ax, [bp+8]
    mov bx, [bp+10]
    mov dl, [bp+12]


  { Bounds checking }
  cmp ax, 0
  jl @exit
  cmp ax, 320
  jge @exit
  cmp bx, 0
  jl @exit
  cmp bx, 200
  jge @exit

  { Calculate screenBase = y * 320 + x }
  mov cx, 320
  mul cx           { DX:AX = Y * 320 }
  add ax, [bp+8]   { add X }
  mov bx, ax       { BX = screenBase }

  { Get image width/height }
  les di, [bp+4]
  mov cx, es:[di]      { width }
  mov dx, es:[di+2]    { height }
  add di, 6            { point to image data }

  { Setup video segment }
  mov ax, seg surface
  mov es, ax
  mov di, offset surface

  { Loop over image rows }
@rowLoop:
  push dx         { save remaining rows }
  push bx         { save current screen offset }

  mov si, cx      { pixels per row }

@colLoop:
  lodsb
  cmp al, dl
  je @skipPixel
  mov es:[di+bx], al

@skipPixel:
  inc bx
  dec si
  jnz @colLoop

  pop bx
  add bx, 320     { next row }
  pop dx
  dec dx
  jnz @rowLoop

@exit:
  pop ds
  pop bp
  end;
end;

procedure asmSpr(
  const image: PBitmap;
  const x, y: integer;
  const transparencyKey: byte);
var
  srcX, srcY, imgWidth, imgHeight: word;
  destX, destY: integer;
  transKey, colour: byte;
begin
  destX := x;
  destY := y;
  imgWidth := image^.width;
  imgHeight := image^.height;
  transKey := transparencyKey;
  colour := 0;

  writeLog('dest x and y:' + i32str(destX) + ', ' + i32str(destY));
  writeLog('img width & height: ' + i32str(imgWidth) + ', ' + i32str(imgHeight));
  writeLog('transparency key' + i32str(transKey));

asm
  les di, [image]

  { Check if image is nil }
  mov ax, es
  or ax, di
  je @skip

  mov srcY, 0  { row counter }

@row_start:
  mov ax, imgHeight
  cmp srcY, ax
  jge @row_end

  mov srcX, 0  { col counter }

@col_start:
  mov ax, imgWidth
  cmp srcX, ax
  jge @col_end

  { Get pixel }
  { Obtain the `data` offset }
  mov ax, srcY
  mov bx, imgWidth
  mul bx
  add ax, srcX  { ax = b * imgWidth + a }

  mov di, 6  { Skip width, height & palsize }
  add di, ax

  { Check if transparent }
  mov al, es:[di]
  mov colour, al
  cmp colour, 13
  je @skip_draw

  { TODO: Check bounds }
  { PSET }
  mov ax, destY
  add ax, srcY
  mov bx, 320
  mul bx
  add ax, destX
  add ax, srcX
  mov bx, ax

  les di, surface
  mov al, colour
  mov es:[di+bx], al


@skip_draw:

  inc srcX
  jmp @col_start

@col_end:

  inc srcY
  jmp @row_start

@row_end:
@skip:
end;

end;


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

  writeLog('dest x and y:' + i32str(destX) + ', ' + i32str(destY));
  writeLog('img width & height: ' + i32str(imgWidth) + ', ' + i32str(imgHeight));
  writeLog('transparency key' + i32str(transKey));

asm
  les di, [image]

  { Check if image is nil }
  mov ax, es
  or ax, di
  je @skip

  add di, 6
  mov word ptr imageDataPtr, di   { store offset }
  mov word ptr imageDataPtr+2, es { store segment }

  mov srcY, 0  { init row counter }

@row_start:
  mov ax, imgHeight
  cmp srcY, ax
  jge @row_end

  mov srcX, 0  { init col counter }

@col_start:
  mov ax, imgWidth
  cmp srcX, ax
  jge @col_end

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
  mov colour, al
  cmp al, 13
  je @skip_draw

  { TODO: Check bounds }

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


@skip_draw:
  inc srcX
  jmp @col_start

@col_end:
  inc srcY
  jmp @row_start

@row_end:
@skip:
end;

end;


procedure asmSprSafe(
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

{
  writeLog('dest x and y:' + i32str(destX) + ', ' + i32str(destY));
  writeLog('img width & height: ' + i32str(imgWidth) + ', ' + i32str(imgHeight));
  writeLog('transparency key' + i32str(transKey));
}

asm
  les di, [image]

  { Check if image is nil }
  mov ax, es
  or ax, di
  je @skip

  add di, 6
  mov word ptr imageDataPtr, di   { store offset }
  mov word ptr imageDataPtr+2, es { store segment }

  mov srcY, 0  { init row counter }

@row_start:
  mov ax, imgHeight
  cmp srcY, ax
  jge @row_end

  mov srcX, 0  { init col counter }

@col_start:
  mov ax, imgWidth
  cmp srcX, ax
  jge @col_end

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
  mov colour, al
  cmp al, 13
  je @skip_draw

  { Check bounds }
  mov ax, destY
  add ax, srcY
  cmp ax, 200
  jge @skip_draw

  mov ax, destX
  add ax, srcX
  cmp ax, 320
  jge @skip_draw

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


@skip_draw:
  inc srcX
  jmp @col_start

@col_end:
  inc srcY
  jmp @row_start

@row_end:
@skip:
end;

end;


procedure sprTint(const image: PBitmap; const x, y: integer; const transparencyKey, tint: byte);
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
procedure spr2(
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

procedure initTrigLUT;
var
  i: integer;
begin
  { Generate sine/cosine lookup table }
  for i := 0 to 35 do begin
    sinLUT[i] := sin(i * 10 * Pi / 180);
    cosLUT[i] := cos(i * 10 * Pi / 180);
    writeLog(i32str(i) + ' - ' + f32str(sinLUT[i]))
  end;
end;

procedure sprPro(const image: PBitmap; const x, y: integer; angle: double; const transparencyKey: byte);
const
  halfsqr2 = 0.70710678; { Math.sqrt(2) / 2 }
var
  sw, sh, cx, cy: integer;
  sa, ca, dx, dy: double;
  ix, iy: integer;
  srcX, srcY: integer;
  colour: byte;
begin
  if image = nil then exit;

  sw:=image^.width;
  sh:=image^.height;
  cx:=sw div 2;
  cy:=sh div 2;

  angle:=angle/180*pi;
  sa:=sin(-angle); { inverse rotation }
  ca:=cos(-angle);

  { bounding box }
  { for iy:=0 to sh-1 do
  for ix:=0 to sw-1 do begin }
  for iy:=trunc(cy-sh * halfsqr2) to trunc(cy+sh * halfsqr2) do
  for ix:=trunc(cx-sw * halfsqr2) to trunc(cx+sw * halfsqr2) do begin
    dx:=ix-cx;
    dy:=iy-cy;

    { inverse rotation }
    srcX:=round(dx*ca - dy*sa + cx);
    srcY:=round(dx*sa + dy*ca + cy);

    if (0<=srcX) and (srcX<sw) and (0<=srcY) and (srcY<sh) then begin
      colour := image^.data[srcY*sw + srcX];
      if colour <> transparencyKey then
        pset(x+ix, y+iy, colour);
    end;
  end;
end;


{ Laggy }
procedure sprPro2(
  const image: PBitmap;
  const x, y: integer;
  const scaleX, scaleY:
  double; angle: double;
  const transparencyKey: byte);
var
  sw, sh, cx, cy: integer;
  sa, ca: double;
  ix, iy: integer; { offset from image centre }
  srcX, srcY: integer;
  hw, hh: integer;
  colour: byte;
begin
  if image = nil then exit;

  sw:=image^.width;
  sh:=image^.height;
  cx:=sw div 2;
  cy:=sh div 2;

  angle:=angle/180*pi;
  sa:=sin(-angle); { inverse rotation }
  ca:=cos(-angle);

  hw:=trunc(sw*scaleX*abs(ca) + sh*scaleY*abs(sa));
  hh:=trunc(sw*scaleX*abs(sa) + sh*scaleY*abs(ca));

  { Debug bounding box }
  {
  pset(-trunc(sw/2 * scaleX), -trunc(sh/2*scaleY), $0E);
  pset( trunc(sw/2 * scaleX), -trunc(sh/2*scaleY), $0E);
  pset( trunc(sw/2 * scaleX),  trunc(sh/2*scaleY), $0E);
  pset(-trunc(sw/2 * scaleX),  trunc(sh/2*scaleY), $0E);
  }

  { bounding box }
  for iy:=-hh to hh do
  for ix:=-hw to hw do begin
    { scaling, then inverse rotation }
    srcX:=round((ix*ca - iy*sa) / scaleX + cx);
    srcY:=round((ix*sa + iy*ca) / scaleY + cy);

    if (0<=srcX) and (srcX<sw) and (0<=srcY) and (srcY<sh) then begin
      colour := image^.data[srcY*sw + srcX];
      if colour <> transparencyKey then
        pset(x+ix, y+iy, colour);
    end;
  end;
end;

{ Laggy despite with lookup tables }
procedure sprProLUT(
  const image: PBitmap;
  const x, y: integer;
  const scaleX, scaleY: double;
  const angle10: integer;
  const transparencyKey: byte);
var
  sw, sh, cx, cy: integer;
  sa, ca: double;
  ix, iy: integer; { offset from image centre }
  srcX, srcY: integer;
  hw, hh: integer;
  angleI32: integer;
  colour: byte;
begin
  if image = nil then exit;

  sw:=image^.width;
  sh:=image^.height;
  cx:=sw div 2;
  cy:=sh div 2;

  { inverse rotation }
  angleI32:=angle10 mod 36;
  sa:=sinLUT[35-angleI32];
  ca:=cosLUT[35-angleI32];

  hw:=trunc(sw*scaleX*abs(ca) + sh*scaleY*abs(sa));
  hh:=trunc(sw*scaleX*abs(sa) + sh*scaleY*abs(ca));

  { bounding box }
  for iy:=-hh to hh do
  for ix:=-hw to hw do begin
    { scaling, then inverse rotation }
    srcX:=round((ix*ca - iy*sa) / scaleX + cx);
    srcY:=round((ix*sa + iy*ca) / scaleY + cy);

    if (0<=srcX) and (srcX<sw) and (0<=srcY) and (srcY<sh) then begin
      colour := image^.data[srcY*sw + srcX];
      if colour <> transparencyKey then
        pset(x+ix, y+iy, colour);
    end;
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
  print('Palette: ' + i32str(image^.palsize) + ' colours', 10, 184, 15)
end;


end.
