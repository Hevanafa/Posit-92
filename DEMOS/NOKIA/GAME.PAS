{$DEFINE DEBUG}

uses
  CRT, DOS,
  Logger, Keyboard, Timing,
  NokiaVGA;

const
  SC_ESC = $01;
var
  done: boolean;
  t: double;
  { DosuEXE: array[0..1] of PBitmap; }
  { TODO: More of your game state here }


procedure clearVGAMem; assembler;
asm
  push es

  { Assign ES:DI to $A000:0000 }
  mov ax, $A000
  mov es, ax
  xor di, di

  xor ax, ax  { reset AX to 0 }
  mov cx, 32000
  cld
  rep stosw

  pop es
end;

procedure INIT;
begin
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initKeyHandler;

  { TODO: Your init code here }

  randomize;
  {
  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
  }
  clearVGAMem;
end;


procedure update;
begin
  updateDeltaTime;

  { TODO: Your update code here }

  if isKeyDown(SC_ESC) then done := true;
  
  t:=t+dt
end;


procedure draw;
begin
  { cls($7D); }

  { TODO: Your drawing code here }

  {
  if (trunc(t * 1.5) and 1) = 0 then
    spr(dosuEXE[0], 148, 76, 13)
  else
    spr(dosuEXE[1], 148, 76, 13);
  }

  print('Hello world!', 160-48, 120, 15);
  { drawMouse; }

  flush
end;


begin
  INIT;

  done := false;

  repeat
    update;
    draw
  until done;

  { TODO: Your cleanup code here }
  {
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);
  }

  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
