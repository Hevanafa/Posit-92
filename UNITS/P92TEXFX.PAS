unit P92TEXFX;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

uses P92TEX;

{ Copied from SprFast, only the pixel plotter is different }
procedure SprTint(const tex: TTexture; const x, y: integer; const tint: byte);


implementation

uses P92VGA;

var
  transparencyKey: byte;

procedure SprTint(const tex: TTexture; const x, y: integer; const tint: byte);
var
  srcX, srcY: integer;
  rowOffset, pxOffset: longint;

  startY, endY: integer;
  startX, endX: integer;

  destOffset: word;
  drawCount: word;

  pixelData: pointer;
  srcAdd: word;
begin
  { Early exits }
  if (x > clipEndX) or (y > clipEndY) then exit;
  if (x + tex.width - 1 < clipStartX) or (y + tex.height - 1 < clipStartY) then exit;

  pixelData := tex.data;

  { Handle vertical clipping }
  startY := 0;
  endY := tex.height - 1;

  if y < clipStartY then startY := clipStartY - y;
  if y + endY > clipEndY then endY := clipEndY - y;

  { Handle horizontal clipping }
  startX := 0;
  endX := tex.width - 1;

  if x < clipStartX then startX := clipStartX - x;
  if x + endX > clipEndX then endX := clipEndX - x;

  { Begin loop }

  for srcY := startY to endY do begin
    destOffset := word(y + srcY) * VGAWidth + word(x + startX);
    drawCount := endX - startX + 1;
    srcAdd := word(srcY) * tex.width + startX;

    asm
      push ds

      les di, backBuffer
      add di, destOffset

      { Load DH with transparencyKey }
      mov dh, transparencyKey

      { Load DS:SI with the source tex's data }
      lds si, pixelData
      add si, srcAdd
      mov cx, drawCount
      mov ah, dh

    @loop:
      lodsb
      cmp al, ah
      je @skip

      mov al, tint
      mov es:[di], al

    @skip:
      inc di
      dec cx
      jnz @loop

      pop ds
    end;
  end;
end;

begin
  transparencyKey := $0D;

end.

