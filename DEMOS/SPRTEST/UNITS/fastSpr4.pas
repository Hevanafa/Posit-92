{ This version works }
procedure fastSpr4(const image: PBitmap; const x, y: integer; const transparencyKey: byte);
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