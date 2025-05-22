{
  BMFont + Effects
  Referenced from https://blinry.org/50-tic80-carts/
}

uses
  CRT, DOS,
  Logger, VGA, Bitmap, BMFont;

var
  done: boolean;
  t: double;
  font: TBMFont;

procedure printOutline(const t: string; const x, y: integer; const colour, outline: byte);
var
  dx, dy: integer;
begin
  for dy:=-1 to 1 do
    for dx:=-1 to 1 do
      print(t, x+dx, y+dy, outline);
  print(t, x, y, colour)
end;

procedure printShadow(const t: string; const x, y: integer; const colour, shadow: byte);
begin
  print(t, x+2, y+2, shadow);
  print(t, x, y, colour)
end;

{ Modified from VGA }
procedure printStripes(const text: string; const x, y: integer);
var
  row, col, idx: integer;
  pos: integer;
  mask, colour: byte;
begin
  for idx := 1 to length(text) do begin
    if (idx < 0) or (idx > 127) then continue;

    for row := 0 to 7 do begin
      mask := font8x8[ord(text[idx]), row];
      colour := row + 8;
      for col := 0 to 7 do
        if (mask and (1 shl (7 - col))) <> 0 then begin
          pset((idx-1) * 8 + x + col, y + row, colour);
          end;
    end;
  end;
end;


procedure INIT;
begin
  randomize;
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  { loadBMFont(font, 'FONTS\FR12.FNT'); }
end;


procedure update;
var
  a: integer;
  ch: char;
begin
  if keyPressed then begin
    ch := readKey;
    if ch = #27 then done := true;
  end;
end;


procedure draw;
var
  a: integer;
begin
  cls($7D);

  printOutline('Outline!', 50, 50, 0, $0B);
  printShadow('Shadow!', 50, 70, $2A, 0);
  printStripes('Stripes!', 50, 90);

  flush
end;


begin
  INIT;
  done := false;

  repeat
    update;
    draw;
  until done;

  freeBuffer;
  closeLogger;
  initTextMode
end.
