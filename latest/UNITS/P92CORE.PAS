unit P92Core;

{$IFDEF FPC}
{$MODE TP}
{$ENDIF}

interface

const
  Posit92Version = '0.1';

type
  TP92Callback = procedure;

  TP92AppConfig = record
    LoadDefaultCursor: boolean;
    EnableAdLib: boolean;
    { Turning this off enables the KeyPressed and ReadKey pattern
      using the CRT unit }
    EnableKeyHandler: boolean;

    { Callbacks }
    OnPreload: TP92Callback;
    OnReady: TP92Callback;
    Update: TP92Callback;
    Draw: TP92Callback;
    { This overrides update & draw loop }
    DrawOnce: TP92Callback;
    OnCleanup: TP92Callback;
  end;


procedure SignalDone;
function FileExists(const filename: string): boolean;

procedure DefaultP92AppConfig(var config: TP92AppConfig);
procedure P92Start(const config: TP92AppConfig);


implementation

uses
  Logger, Timing,
  PCS, AdLib,
  Keyboard, Mouse,
  FPS, VGA
{$ifdef P92_MODEX}
  , ModeX;
{$else}
  ;
{$endif}

var
  done: boolean;
  bootConfig: TP92AppConfig;

procedure SignalDone;
begin
  done := true
end;

function FileExists(const filename: string): boolean;
var
  f: file;
begin
  {$I-}  { Turn off runtime error 2: IO error halt }
  assign(f, filename);
  reset(f);
  FileExists := (IOResult = 0);
  close(f)  { Safe, even if the file isn't open }
  {$I+}
end;

procedure DefaultP92AppConfig(var config: TP92AppConfig);
begin
  config.LoadDefaultCursor := true;
  config.EnableAdLib := false;
  config.EnableKeyHandler := true;

  @config.OnPreload := nil;
  @config.OnReady := nil;
  @config.Update := nil;
  @config.Draw := nil;
  @config.OnCleanup := nil;
end;

{ Called by P92Start }
procedure P92Init;
begin
  Randomize;

  InitLogger;

{$ifdef P92_MODEX}
  InitVGAMode;
  initModeX;
  loadFont;
{$else}
  InitVGAMode;
  LoadCGAFont;
{$endif}

  InitBuffer;
  InitDeltaTime;

  if bootConfig.EnableKeyHandler then
    InitKeyHandler;

  InitMouse;

  if bootConfig.LoadDefaultCursor then
    LoadCursor;

  InitFPSCounter;

  if bootConfig.EnableAdLib then
    AdlibDrv.init;
end;

procedure P92Cleanup;
begin
  ResetMouse;

  if bootConfig.EnableKeyHandler then
    ResetKeyHandler;

  if bootConfig.EnableAdLib then
    AdLibDrv.shutdown;

  FreeBuffer;
  CloseLogger;
  InitTextMode;
end;

procedure P92Update;
begin
  UpdateDeltaTime;
  UpdateMouse;
  IncrementFPS;

  if bootConfig.EnableAdLib then
    AdlibDrv.update;
end;

procedure P92Draw;
begin
  { no-op }
end;

procedure P92AfterDraw;
begin
  if bootConfig.LoadDefaultCursor then
    DrawMouse;

  DrawFPS;

{$ifdef P92_MODEX}
  flipPages;
{$else}
  Flush;
{$endif}
end;

{ Game engine entry point }
procedure P92Start(const config: TP92AppConfig);
const
  TargetFPS = 35;
  {
    Sleep in HLT while waiting for the next frame
    HLT introduces a wake up delay
    Waiting for a full 1/35 second produces about 25 FPS
    Poll at twice the target frequency to obtain approximately 35 FPS
  }
  WaitFrequency = TargetFPS * 2;
var
  now, nextTick: double;
begin
  bootConfig := config;
  P92Init;

  if @config.OnPreload <> nil then
    config.OnPreload;

  if @config.OnReady <> nil then
    config.OnReady;

  if @config.DrawOnce <> nil then begin
    config.DrawOnce;
    Print('Press Enter to exit', 0, vgaheight - 8, $0F);
    Flush;
    ResetKeyHandler;
    ReadLn;
  end else begin
    now := GetTimer;
    nextTick := now;

    repeat
      now := GetTimer;
      nextTick := now + 1 / WaitFrequency;

      P92Update;
      config.Update;

      P92Draw;
      config.Draw;
      P92AfterDraw;

      { Wait for the next frame }
      while GetTimer < nextTick do
      asm
        sti
        hlt
      end;
    until done;

  {
    done := false;

    repeat
      P92Update;
      config.Update;

      P92Draw;
      config.Draw;
      P92AfterDraw;
    until done;
  }
  end;

  if @config.OnCleanup <> nil then
    config.OnCleanup;

  P92Cleanup
end;


end.

