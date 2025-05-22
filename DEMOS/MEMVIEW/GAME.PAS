{
  Show remaining memory demo
}

uses
  CRT, DOS,
  Logger, VGA, Memory;

var
  done: boolean;

procedure INIT;
begin
  randomize;
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
end;


procedure update;
var
  ch: char;
begin
  if keyPressed then begin
    ch := readKey;
	if ch = #27 then done := true;
  end;
end;


procedure draw;
begin
  cls($7D);
  drawMemInfo;
  drawDOSMemInfo;
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
