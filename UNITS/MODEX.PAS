unit ModeX;

interface

procedure initVGAMode;
procedure initModeX;
procedure initTextMode;
procedure cls(const colour: byte);
procedure PSET(const x, y: integer; const colour: byte);
procedure setDisplayPage(const page: byte);
procedure flipPages;

implementation

var
  drawPage, displayedPage: byte;

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
end;

procedure initTextMode; assembler;
asm
  mov ax, 0003h
  int 10h
end;

procedure cls(const colour: byte);
begin
  fillChar(Mem[$A000:drawPage * $4000], 64000, colour)
end;

procedure PSET(const x, y: integer; const colour: byte);
var
  offset: integer;
  plane: byte;
begin
  offset := (drawPage * $4000) + y * 80 + (x shr 2);  { x div 4 }
  plane := 1 shl (x and 3);

  port[$3C4] := $02;
  port[$3C5] := plane;
  Mem[$A000:offset] := colour
end;

procedure setDisplayPage(const page: byte);
begin
  port[$3D4] := $0C;
  port[$3D5] := hi(page * $4000);
  port[$3D4] := $0D;
  port[$3D5] := lo(page * $4000);
end;

procedure flipPages;
begin
  drawPage := 1 - drawPage;
  displayedPage := 1 - displayedPage;
  setDisplayPage(displayedPage)
end;


end.
