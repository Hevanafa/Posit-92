
uses
  CRT,
  P92CONV, P92FPS, P92TIME, P92MNTEX, P92MONO, P92VGA;

procedure PSet10000;
var
  a: word;
  startTick, endTick: double;
begin
  startTick := GetTimer;

  { 0.0673s }
  for a:=1 to 10000 do
    PSet1BPP(random(VGAWidth + 10) - 5, random(VGAHeight + 10) - 5, 1);

  { 0.0618s }
  {
  for a:=1 to 10000 do
    AsmPSet1BPP(random(VGAWidth + 10) - 5, random(VGAHeight + 10) - 5, 1);
  }

  endTick := GetTimer;

  Print1BPP('10000 operations done in ' + F32Str(endTick - startTick) + 's', 0, 0, 1)
end;


procedure Present100;
var
  startTick, endTick: double;
  a: word;
begin
  startTick := GetTimer;

  { Without LUT: 6.8057s
    With LUT: 2.0417s
    AsmPresent: 1.3009s, 1.1956s }
  for a:=1 to 100 do
    Present1BPP;

  { AsmPresent_2: 0.9346s }
  { for a:=1 to 100 do
    AsmPresent1BPP_2; }

  endTick := GetTimer;

  Print1BPP('100 present ops done in ' + F32Str(endTick - startTick) + 's', 0, 0, 1);

  Present1BPP;
end;

var
  done: boolean;
begin
  LoadCGAFont;

  InitBuffer(320, 200);
  InitMode13h;

  InitDeltaTime;
  InitFPSCounter;

  done := false;

  repeat
    { Update }
    UpdateDeltaTime;
    IncrementFPS;

    if KeyPressed and (ReadKey = #27) then done := true;

    { Draw }
    Cls1BPP($00);

    { PSet1BPP(10, 10, 1); }
    Print1BPP('Hello from MONOVGA!', (VGAWidth - 152) div 2, 100, 1);

    Print1BPP('FPS:' + I32Str(GetLastFPS), 240, 0, 1);

    Present1BPP;
  until done;

  { Benchmarking procedures }
  { PSet10000; }
  { Present100; }

  FreeBuffer;
  InitModeText;
end.
