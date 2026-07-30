{$DEFINE DEBUG}
{$R+}

uses
  CRT, DOS,
  P92Core, Conv, Logger, P92KBD, Timing,
  BMFont, P92VGA; { , NokiaVGA; }

var
  { Asset variables }
  nokiaFont, p8Font: PBMFont;
  { Game state variables }
  startTick, t: double;
  palette: array[0..1] of byte;


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


procedure nokiaFlushX2;
var
  x, y: word;
  surfacePtr: pointer;
begin
  surfacePtr := surface;
asm
  push es

  { Assign ES:DI to VGA memory }
  mov ax, $A000
  mov es, ax
  xor di, di

  push ds
  lds si, surface
  { mov si, offset surface }

@y_init:
  { reset y to 0 }
  { xor y, y }  { Not possible with TP7 }
  mov y, 0

@y_condition:
  cmp y, 48
  jge @y_end

@y_loop:

  mov cx, 84  { Used together with `loop` }

@x_loop:
  mov bx, di

  mov al, ds:[si]  { obtain the source colour }
  mov es:[di], al
  inc di
  mov es:[di], al
  inc di
  mov es:[bx+320], al
  mov es:[bx+321], al

  add bx, 2
  inc si

  loop @x_loop  { decrement cx, pass if cx = 0 }

@y_next:
  add di, 472  { (320 - 168) + 320 = 152 + 320 }
  inc y
  jmp @y_condition

@y_end:

  pop ds
  pop es
end;
end;


procedure OnPreload; far;
begin
  loadBMFont(nokiaFont, 'FONTS\NOKIA.TXT');
  loadBMFont(p8Font, 'FONTS\P8.TXT');
end;

procedure OnCleanup; far;
begin
  freeBMFont(nokiaFont);
  freeBMFont(p8Font);
end;

procedure OnReady; far;
begin
  palette[0] := 98;
  palette[1] := 8;

  clearVGAMem;

  startTick := getTimer;
end;


procedure Update; far;
begin
  if isKeyDown(SC_ESCAPE) then SignalDone;
  
  t := getTimer - startTick
end;


procedure Draw; far;
var
  x: double;
  a: byte;
begin
  cls(palette[0]);

  PrintBMFont(nokiaFont, 'Hello Nokia!', 4, 4);
  PrintBMFont(p8Font, 'hello pico-8!', 4, 16);

  { Sine wave demo }
  for a:=0 to 47 do begin
    x := 42 + sin(t + a * 0.1) * 40;
    pset(trunc(x), a, palette[1]);
  end;

  { nokiaFlush; }
  { nokiaFlushX2; }
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.LoadDefaultCursor := false;
  appConfig.EnableDrawFPS := false;
  { appConfig.EnableDefaultPresent := false; }

  appConfig.BufferWidth := 84;
  appConfig.BufferHeight := 48;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

