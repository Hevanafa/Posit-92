unit ModeX;

interface

procedure initVGAMode;
procedure initModeX;
procedure initTextMode;
procedure loadFont;
procedure cls(const colour: byte);
procedure PSET(const x, y: integer; const colour: byte);
procedure print(const text: string; const x, y: integer; const colour: byte);
procedure setDisplayPage(const page: byte);
procedure setActivePage(const page: byte);
procedure flipPages;

implementation

uses DOS;

const
  pageSize = $4b00; { 19200 bytes }

var
  drawPage, displayedPage: byte;
  font8x8: array[0..127, 0..7] of byte;

procedure initVGAMode; assembler;
asm
  mov ax, 0013h
  int 10h
end;

procedure initModeX;
begin
  initVGAMode;

  { Modify VGA registers for Mode X }
  Port[$3C4] := $04;  Port[$3C5] := $06;  { Memory mode register }
  Port[$3D4] := $14;  Port[$3D5] := $00;  { Underline location }
  Port[$3D4] := $17;  Port[$3D5] := $E3;  { Mode control }
  
  drawPage := 0;
  displayedPage := 1;
  
  setDisplayPage(displayedPage);
  setActivePage(drawPage);
end;

procedure initTextMode; assembler;
asm
  mov ax, 0003h
  int 10h
end;

{ Load 8x8 font }
procedure loadFont;
var
  Regs: Registers;
begin
  { Get the 8x8 font pointer }
  regs.ah := $11;
  regs.al := $30;
  regs.bh := 3; { 8x8 font }
  Intr($10, Regs);

  { Copy font data to buffer }
  Move(Mem[Regs.ES:Regs.BP], font8x8, sizeOf(font8x8));
end;

procedure cls(const colour: byte);
begin
  port[$3C4] := $02;  { Select "map mask register", basically the plane that you can write to }
  port[$3C5] := $0f;  { Enable all 4 planes: 0000 1111 -> all the 4 planes are enabled }
  
  fillChar(Mem[$A000:drawPage * pageSize], 19200, colour)
end;

procedure PSET(const x, y: integer; const colour: byte);
var
  offset: integer;
begin
  { Bounds check }
  if (x < 0) or (x >= 320) or (y < 0) or (y >= 240) then exit;
  
  offset := (drawPage * pageSize) + y * 80 + (x shr 2);   { x div 4 }
  
  { Set write page }
  port[$3C4] := $02;
  port[$3C5] := 1 shl (x and 3);  { Enable only 1 plane, depending on the x }
  Mem[$A000:offset] := colour
end;

{ Based on the print procedure from VGA unit }
procedure print(const text: string; const x, y: integer; const colour: byte);
var
  row, col, idx: integer;
  pos: integer;
  mask: byte;
begin
  for idx := 1 to length(text) do begin
    if (idx < 0) or (idx > 127) then continue;

    for row := 0 to 7 do begin
      mask := font8x8[ord(text[idx]), row];
      for col := 0 to 7 do
        if (mask and (1 shl (7 - col))) <> 0 then
          pset((idx-1) * 8 + x + col, y + row, colour);
    end;
  end;
end;

procedure setActivePage(const page: byte);
begin
  port[$3D4] := $0C;
  port[$3D5] := hi(page * pageSize);
  port[$3D4] := $0D;
  port[$3D5] := lo(page * pageSize);
end;

procedure setDisplayPage(const page: byte);
begin
  port[$3D4] := $0C;
  port[$3D5] := hi(page * pageSize);
  port[$3D4] := $0D;
  port[$3D5] := lo(page * pageSize);
end;

procedure flipPages;
begin
  drawPage := 1 - drawPage;
  displayedPage := 1 - displayedPage;
  
  setDisplayPage(displayedPage);
  setActivePage(drawPage)
end;


end.
