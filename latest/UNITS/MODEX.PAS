unit ModeX;

interface

{ Requires InitMode13h call }
procedure InitModeX;

procedure Cls(const colour: byte);
procedure PSet(const x, y: integer; const colour: byte);
procedure Print(const text: string; const x, y: integer; const colour: byte);

procedure SetVisiblePage(const page: byte);
procedure FlipModeXPage;


implementation

uses
  DOS, VGA;

{
  Mode X page start addresses (19200 bytes each):
  $0000, $4b00, $9600, $E100
}
const
  pageSize = $4b00;

var
  drawPage: byte;

procedure InitModeX;
begin
  { Modify VGA registers for Mode X }
  Port[$3C4] := $04;  Port[$3C5] := $06;  { Memory mode register }
  Port[$3D4] := $14;  Port[$3D5] := $00;  { Underline location }
  Port[$3D4] := $17;  Port[$3D5] := $E3;  { Mode control }
  
  drawPage := 0;
  SetVisiblePage(1 - drawPage)
end;

procedure Cls(const colour: byte);
begin
  port[$3C4] := $02;  { Select "map mask register", basically the plane that you can write to }
  port[$3C5] := $0f;  { Enable all 4 planes: 0000 1111 -> all the 4 planes are enabled }
  
  fillChar(Mem[$A000:drawPage * pageSize], 19200, colour)
end;

procedure PSet(const x, y: integer; const colour: byte);
var
  offset: integer;
begin
  { Bounds check }
  if (x < 0) or (x >= 320) or (y < 0) or (y >= 240) then exit;
  
  offset := (drawPage * pageSize) + y * 80 + (x shr 2);   { x div 4 }
  
  { Set write page }
  port[$3C4] := $02; { Select "map mask register" }
  port[$3C5] := 1 shl (x and 3);  { Enable only 1 plane, depending on the x }
  Mem[$A000:offset] := colour
end;

{ Based on the Print procedure from VGA unit }
procedure Print(const text: string; const x, y: integer; const colour: byte);
var
  row, col, idx: integer;
  pos: integer;
  mask: byte;
begin
  for idx := 1 to length(text) do begin
    if (idx < 0) or (idx > 127) then continue;

    for row := 0 to 7 do begin
      mask := BorrowCGAFont^[ord(text[idx]), row];
      for col := 0 to 7 do
        if (mask and (1 shl (7 - col))) <> 0 then
          PSet((idx-1) * 8 + x + col, y + row, colour);
    end;
  end;
end;

{ Tells the VGA to start displaying pixels from memory address X }
procedure SetVisiblePage(const page: byte);
begin
  port[$3D4] := $0C;  { CRTC address register - "Start Address High" }
  port[$3D5] := hi(page * pageSize); { Write high byte of start address }
  port[$3D4] := $0D;  { CRTC address register - "Start Address Low" }
  port[$3D5] := lo(page * pageSize); { Write low byte of start address }
end;

procedure WaitForVSync;
begin
  { Wait for the end of current retrace (if in one) }
  while (port[$3DA] and $08) <> 0 do;
  { Wait for the start of next retrace }
  while (port[$3DA] and $08) = 0 do;
end;

procedure FlipModeXPage;
begin
  WaitForVSync;
  drawPage := 1 - drawPage;
  SetVisiblePage(1 - drawPage)
end;


end.
