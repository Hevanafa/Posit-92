{$DEFINE DEBUG}

uses
  CRT, DOS,
  Bitmap, Logger, Keyboard, Mouse, PCS, Timing, VGA;

const
  SC_ESC = $01;

  C4 = 262;
  D4 = 294;
  E4 = 330;
  F4 = 349;
  G4 = 392;
  A4 = 440;
  B4 = 494;
  C5 = 523;
  D5 = 587;
  E5 = 659;
  F5 = 698;
  G5 = 784;

  quart = 0.5;
  threeEighth = 0.75;
  half = 1;
  full = 2;

var
  done: boolean;
  t: double;
  DosuEXE: array[0..1] of PBitmap;
  hymn: TMelody;
  { TODO: More of your game state here }


procedure INIT;
begin
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initKeyHandler;
  initMouse;

  { TODO: Your init code here }

  randomize;
  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
  PCSpeaker.init;
end;

{
procedure initJerusalemHymn;
begin
  hymn.noteCount := 128;

  initNote(hymn.notes[0], G4, 0.25);
  initNote(hymn.notes[1], G4, 0.25);
  initNote(hymn.notes[2], A4, 0.25);
  initNote(hymn.notes[3], B4, 0.5);
  initNote(hymn.notes[4], C5, 0.25);
  initNote(hymn.notes[5], B4, 0.25);
  initNote(hymn.notes[6], A4, 0.5);
  initNote(hymn.notes[7], G4, 0.75);

  initNote(hymn.notes[8], B4, 0.25);
  initNote(hymn.notes[9], B4, 0.25);
  initNote(hymn.notes[10], C5, 0.25);
  initNote(hymn.notes[11], D5, 0.5);
  initNote(hymn.notes[12], E5, 0.25);
  initNote(hymn.notes[13], D5, 0.25);
  initNote(hymn.notes[14], C5, 0.5);
  initNote(hymn.notes[15], G4, 1);
end;
}

procedure initJerusalemHymn;
begin
  hymn.noteCount := 128;

  { and did those feet in ancient time }
  initNote(hymn.notes[0], G4, quart);
  initNote(hymn.notes[1], G4, quart);
  initNote(hymn.notes[2], A4, quart);
  initNote(hymn.notes[3], B4, half);
  initNote(hymn.notes[4], C5, quart);
  initNote(hymn.notes[5], B4, quart);
  initNote(hymn.notes[6], A4, half);
  initNote(hymn.notes[7], G4, half + quart);

  initNote(hymn.notes[8], B4, quart);
  initNote(hymn.notes[9], B4, quart);
  initNote(hymn.notes[10], C5, quart);
  initNote(hymn.notes[11], D5, half);
  initNote(hymn.notes[12], E5, quart);
  initNote(hymn.notes[13], D5, quart);
  initNote(hymn.notes[14], C5, half);
  initNote(hymn.notes[15], G4, full);

  initNote(hymn.notes[16], 392, quart);
  initNote(hymn.notes[17], 392, quart);
  initNote(hymn.notes[18], 440, quart);
  initNote(hymn.notes[19], 494, half);
  initNote(hymn.notes[20], 523, quart);
  initNote(hymn.notes[21], 494, quart);
  initNote(hymn.notes[22], 440, half);
  initNote(hymn.notes[23], 392, half + quart);

  initNote(hymn.notes[24], 494, quart);
  initNote(hymn.notes[25], 494, quart);
  initNote(hymn.notes[26], 523, quart);
  initNote(hymn.notes[27], 587, half);
  initNote(hymn.notes[28], 659, quart);
  initNote(hymn.notes[29], 587, quart);
  initNote(hymn.notes[30], 523, half);
  initNote(hymn.notes[31], 392, full);

  { Bring me my bow of burning gold }
  initNote(hymn.notes[32], 392, 0.75);
  initNote(hymn.notes[33], 523, 0.75);
  initNote(hymn.notes[34], 523, 0.5);
  initNote(hymn.notes[35], 494, 0.5);
  initNote(hymn.notes[36], 440, 0.5);
  initNote(hymn.notes[37], 392, 0.75);
  initNote(hymn.notes[38], 330, 0.75);
  initNote(hymn.notes[39], 392, 1.5);
  
  initNote(hymn.notes[40], 392, 0.75);
  initNote(hymn.notes[41], 523, 0.75);
  initNote(hymn.notes[42], 523, 0.5);
  initNote(hymn.notes[43], 587, 0.5);
  initNote(hymn.notes[44], 659, 0.5);
  initNote(hymn.notes[45], 587, 0.75);
  initNote(hymn.notes[46], 523, 0.75);
  initNote(hymn.notes[47], 494, 1.5);

  initNote(hymn.notes[48], 494, 0.75);
  initNote(hymn.notes[49], 659, 0.75);
  initNote(hymn.notes[50], 659, 0.5);
  initNote(hymn.notes[51], 587, 0.5);
  initNote(hymn.notes[52], 523, 0.5);
  initNote(hymn.notes[53], 494, 0.75);
  initNote(hymn.notes[54], 440, 0.75);
  initNote(hymn.notes[55], 392, 1.5);

  initNote(hymn.notes[56], 392, 0.75);
  initNote(hymn.notes[57], 523, 0.75);
  initNote(hymn.notes[58], 523, 0.5);
  initNote(hymn.notes[59], 494, 0.5);
  initNote(hymn.notes[60], 440, 0.5);
  initNote(hymn.notes[61], 392, 0.75);
  initNote(hymn.notes[62], 330, 0.75);
  initNote(hymn.notes[63], 294, 2.0);

  { I will not cease from mental fight }
  initNote(hymn.notes[64], 392, 0.5);
  initNote(hymn.notes[65], 392, 0.5);
  initNote(hymn.notes[66], 440, 0.5);
  initNote(hymn.notes[67], 494, 1.0);
  initNote(hymn.notes[68], 523, 0.5);
  initNote(hymn.notes[69], 494, 0.5);
  initNote(hymn.notes[70], 440, 1.0);
  initNote(hymn.notes[71], 392, 1.5);

  initNote(hymn.notes[72], 494, 0.5);
  initNote(hymn.notes[73], 494, 0.5);
  initNote(hymn.notes[74], 523, 0.5);
  initNote(hymn.notes[75], 587, 1.0);
  initNote(hymn.notes[76], 659, 0.5);
  initNote(hymn.notes[77], 587, 0.5);
  initNote(hymn.notes[78], 523, 1.0);
  initNote(hymn.notes[79], 392, 1.5);

  initNote(hymn.notes[80], 392, 0.5);
  initNote(hymn.notes[81], 392, 0.5);
  initNote(hymn.notes[82], 440, 0.5);
  initNote(hymn.notes[83], 494, 1.0);
  initNote(hymn.notes[84], 523, 0.5);
  initNote(hymn.notes[85], 494, 0.5);
  initNote(hymn.notes[86], 440, 1.0);
  initNote(hymn.notes[87], 392, 1.5);

  initNote(hymn.notes[88], 494, 0.5);
  initNote(hymn.notes[89], 494, 0.5);
  initNote(hymn.notes[90], 523, 0.5);
  initNote(hymn.notes[91], 587, 1.0);
  initNote(hymn.notes[92], 659, 0.5);
  initNote(hymn.notes[93], 587, 0.5);
  initNote(hymn.notes[94], 523, 1.0);
  initNote(hymn.notes[95], 392, 3.0);
end;


procedure update;
begin
  updateDeltaTime;
  updateMouse;
  PCSpeaker.update;

  { TODO: Your update code here }

  if isKeyDown(SC_ESC) then done := true;
  
  t:=t+dt
end;


procedure draw;
begin
  asmCls($7D);

  { TODO: Your drawing code here }

  if (trunc(t * 1.5) and 1) = 0 then
    asmSpr(dosuEXE[0], 148, 76, 13)
  else
    asmSpr(dosuEXE[1], 148, 76, 13);

  print('Hello world!', 160-48, 120, 15);
  drawMouse;

  asmFlush
end;


begin
  INIT;
  done := false;
  initJerusalemHymn;
  PCSpeaker.playMelody(hymn);

  repeat
    update;
    draw
  until done;

  { TODO: Your cleanup code here }
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);

  PCSpeaker.stop;

  resetMouse;
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
