{$DEFINE DEBUG}

uses
  CRT, DOS,
  P92Core, P92TEX, P92LOG, PCSPKR, Timing, P92VGA;

const
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

  quart = 0.25;
  threeEighth = 0.375;
  half = 0.5;
  threeFourth = 0.75;
  full = 1.0;

var
  { Asset variables }
  DosuEXE: array[0..1] of TTexture;
  imgPiano: TTexture;
  hymn: TMelody;

  { Game state variables}
  t: double;

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

procedure InitJerusalemHymn;
begin
  CreateMelody(hymn, 96);

  { and did those feet in ancient time }
  InitNote(hymn.notes^[0], G4, quart);
  InitNote(hymn.notes^[1], G4, quart);
  InitNote(hymn.notes^[2], A4, quart);
  InitNote(hymn.notes^[3], B4, half);
  InitNote(hymn.notes^[4], C5, quart);
  InitNote(hymn.notes^[5], B4, quart);
  InitNote(hymn.notes^[6], A4, half);
  InitNote(hymn.notes^[7], G4, threeFourth);

  InitNote(hymn.notes^[8], B4, quart);
  InitNote(hymn.notes^[9], B4, quart);
  InitNote(hymn.notes^[10], C5, quart);
  InitNote(hymn.notes^[11], D5, half);
  InitNote(hymn.notes^[12], E5, quart);
  InitNote(hymn.notes^[13], D5, quart);
  InitNote(hymn.notes^[14], C5, half);
  InitNote(hymn.notes^[15], G4, full);

  InitNote(hymn.notes^[16], G4, quart);
  InitNote(hymn.notes^[17], G4, quart);
  InitNote(hymn.notes^[18], A4, quart);
  InitNote(hymn.notes^[19], B4, half);
  InitNote(hymn.notes^[20], C5, quart);
  InitNote(hymn.notes^[21], B4, quart);
  InitNote(hymn.notes^[22], A4, half);
  InitNote(hymn.notes^[23], G4, threeFourth);

  InitNote(hymn.notes^[24], B4, quart);
  InitNote(hymn.notes^[25], B4, quart);
  InitNote(hymn.notes^[26], C5, quart);
  InitNote(hymn.notes^[27], D5, half);
  InitNote(hymn.notes^[28], E5, quart);
  InitNote(hymn.notes^[29], D5, quart);
  InitNote(hymn.notes^[30], C5, half);
  InitNote(hymn.notes^[31], G4, full);

  { Bring me my bow of burning gold }
  InitNote(hymn.notes^[32], G4, threeEighth);
  InitNote(hymn.notes^[33], C5, threeEighth);
  InitNote(hymn.notes^[34], C5, quart);
  InitNote(hymn.notes^[35], B4, quart);
  InitNote(hymn.notes^[36], A4, quart);
  InitNote(hymn.notes^[37], G4, threeEighth);
  InitNote(hymn.notes^[38], E4, threeEighth);
  InitNote(hymn.notes^[39], G4, threeFourth);
  
  InitNote(hymn.notes^[40], G4, threeEighth);
  InitNote(hymn.notes^[41], C5, threeEighth);
  InitNote(hymn.notes^[42], C5, quart);
  InitNote(hymn.notes^[43], D5, quart);
  InitNote(hymn.notes^[44], E5, quart);
  InitNote(hymn.notes^[45], D5, threeEighth);
  InitNote(hymn.notes^[46], C5, threeEighth);
  InitNote(hymn.notes^[47], B4, threeFourth);

  InitNote(hymn.notes^[48], B4, threeEighth);
  InitNote(hymn.notes^[49], E5, threeEighth);
  InitNote(hymn.notes^[50], E5, quart);
  InitNote(hymn.notes^[51], D5, quart);
  InitNote(hymn.notes^[52], C5, quart);
  InitNote(hymn.notes^[53], B4, threeEighth);
  InitNote(hymn.notes^[54], A4, threeEighth);
  InitNote(hymn.notes^[55], G4, threeFourth);

  InitNote(hymn.notes^[56], G4, threeEighth);
  InitNote(hymn.notes^[57], C5, threeEighth);
  InitNote(hymn.notes^[58], C5, quart);
  InitNote(hymn.notes^[59], B4, quart);
  InitNote(hymn.notes^[60], A4, quart);
  InitNote(hymn.notes^[61], G4, threeEighth);
  InitNote(hymn.notes^[62], E4, threeEighth);
  InitNote(hymn.notes^[63], D4, full);

  { I will not cease from mental fight }
  InitNote(hymn.notes^[64], G4, quart);
  InitNote(hymn.notes^[65], G4, quart);
  InitNote(hymn.notes^[66], A4, quart);
  InitNote(hymn.notes^[67], B4, half);
  InitNote(hymn.notes^[68], C5, quart);
  InitNote(hymn.notes^[69], B4, quart);
  InitNote(hymn.notes^[70], A4, half);
  InitNote(hymn.notes^[71], G4, threeFourth);

  InitNote(hymn.notes^[72], B4, quart);
  InitNote(hymn.notes^[73], B4, quart);
  InitNote(hymn.notes^[74], C5, quart);
  InitNote(hymn.notes^[75], D5, half);
  InitNote(hymn.notes^[76], E5, quart);
  InitNote(hymn.notes^[77], D5, quart);
  InitNote(hymn.notes^[78], C5, half);
  InitNote(hymn.notes^[79], G4, threeFourth);

  InitNote(hymn.notes^[80], G4, quart);
  InitNote(hymn.notes^[81], G4, quart);
  InitNote(hymn.notes^[82], A4, quart);
  InitNote(hymn.notes^[83], B4, half);
  InitNote(hymn.notes^[84], C5, quart);
  InitNote(hymn.notes^[85], B4, quart);
  InitNote(hymn.notes^[86], A4, half);
  InitNote(hymn.notes^[87], G4, threeFourth);

  InitNote(hymn.notes^[88], B4, quart);
  InitNote(hymn.notes^[89], B4, quart);
  InitNote(hymn.notes^[90], C5, quart);
  InitNote(hymn.notes^[91], D5, half);
  InitNote(hymn.notes^[92], E5, quart);
  InitNote(hymn.notes^[93], D5, quart);
  InitNote(hymn.notes^[94], C5, half);
  InitNote(hymn.notes^[95], G4, full + half);
end;

procedure OnPreload; far;
begin
  LoadTex(imgPiano, 'IMG\PIANO.BMP');
  InitJerusalemHymn;
end;

procedure OnCleanup; far;
begin
  FreeTex(imgPiano);
  FreeMelody(hymn);
end;

procedure OnReady; far;
begin
  PlayMelody(@hymn);
end;

procedure Update; far;
begin
  if KeyPressed and (ReadKey = #27) then SignalDone;
  
  t:=t+DeltaTime;
end;


procedure Draw; far;
begin
  Cls($7D);

  Spr(imgPiano, 148, 76);

  Print('Playing "Jerusalem" hymn', 160-96, 120, 15);
  Print('by Sir Charles Hubert', 160-84, 130, 15);
  Print('Hastings Parry', 160-56, 140, 15);
end;


var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.EnableKeyHandler := false;
  appConfig.LoadDefaultCursor := false;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.

