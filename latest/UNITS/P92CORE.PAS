unit P92Core;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

uses BMFont;

const
  Posit92Version = '0.1';

type
  TP92Callback = procedure;

  TP92WaitMode = (
    P92WaitHLT,
    P92WaitBusy,
    P92WaitVSync,
    P92WaitUncapped
  );

  TP92AppConfig = record
    BufferWidth: word;
    BufferHeight: word;

    TargetFPS: word;
    WaitMode: TP92WaitMode;

    LoadDefaultCursor: boolean;
    EnablePCSpeaker: boolean;
    EnableAdLib: boolean;
    { Turning this off enables the KeyPressed and ReadKey pattern
      using the CRT unit }
    EnableKeyHandler: boolean;

    EnableDrawFPS: boolean;
    EnableDefaultPresent: boolean;

    DefaultBMFont: PBMFont;

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
  DOS,
  P92LOG, Timing, P92MEM, P92KBD, P92Mouse, FPS, P92VGA, PCSPKR, AdLib, Panic
{$IFDEF P92_IMGUI}
  , P92IMGUI
{$ENDIF}
{$ifdef P92_MODE_X}
  , ModeX
{$endif}
  ;

var
  done: boolean;
  bootConfig: TP92AppConfig;

{
  Sleep in HLT while waiting for the next frame
  HLT introduces a wake up delay
  Waiting for a full 1/35 second produces about 25 FPS
  Poll at twice the target frequency to obtain approximately 35 FPS

  Note: This only applies to P92WaitHLT
}
  WaitFrequency: word;


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
  config.BufferWidth := DefaultVGAWidth;
  config.BufferHeight := DefaultVGAHeight;

  config.TargetFPS := 35;
  config.WaitMode := P92WaitHLT;
  WaitFrequency := config.TargetFPS * 2;

  config.LoadDefaultCursor := true;

  config.EnablePCSpeaker := true;
  config.EnableAdLib := false;
  config.EnableKeyHandler := true;

  config.EnableDrawFPS := true;
  config.EnableDefaultPresent := true;

  config.DefaultBMFont := nil;

  @config.OnPreload := nil;
  @config.OnReady := nil;
  @config.Update := nil;
  @config.Draw := nil;
  @config.OnCleanup := nil;
end;

{ Called by P92Start }
procedure P92Init;
begin
  InitLogger;
  InitMode13h;
{$ifdef P92_MODE_X}
  initModeX;
{$endif}
  LoadCGAFont;

  InitBuffer(bootConfig.BufferWidth, bootConfig.BufferHeight);

  InitDeltaTime;

  if bootConfig.EnableKeyHandler then
    InitKeyHandler;

  InitMouse;

  if bootConfig.LoadDefaultCursor then
    LoadCursor;

  InitFPSCounter;

  if bootConfig.EnablePCSpeaker then
    PCSpkr.Init;

  if bootConfig.EnableAdLib then
    Adlib.Init;

  { Randomize; }
  RandSeed := trunc(GetTimer);
end;

procedure P92Cleanup;
begin
  ResetMouse;

  if bootConfig.EnableKeyHandler then
    ResetKeyHandler;

  if bootConfig.EnablePCSpeaker then
    PCSpkr.Stop;

  if bootConfig.EnableAdLib then
    AdLib.Shutdown;

  FreeBuffer;
  CloseLogger;
  InitModeText;
end;

procedure P92Update;
begin
  UpdateDeltaTime;

{$IFDEF P92_IMGUI}
  ResetWidgetIndices;

  UpdateGUILastMouseButton;
  UpdateMouse;
  UpdateGUIMousePoint;
{$ELSE}
  UpdateMouse;
{$ENDIF}

  IncrementFPS;

  if bootConfig.EnablePCSpeaker then
    PCSpkr.Update;

  if bootConfig.EnableAdLib then
    AdLib.Update;
end;

procedure P92Draw;
begin
  { no-op }
end;

procedure P92AfterDraw;
begin
{$IFDEF P92_IMGUI}
  ResetActiveWidget;
{$ENDIF}

  if bootConfig.EnableDrawFPS then
    DrawFPS;

{$ifdef P92_MODE_X}
  FlipModeXPage;
{$else}
  if bootConfig.EnableDefaultPresent then
    PresentMode13h;
{$endif}

  if bootConfig.LoadDefaultCursor then
    DrawMouse;
end;

{ Various timing techniques }

procedure P92RunFrame;
begin
  P92Update;
  bootConfig.Update;

  P92Draw;
  bootConfig.Draw;
  P92AfterDraw;
end;

{ Perform the sti/hlt pair loop
  This is the default for demos and games }
procedure P92RunHLT;
var
  now, nextTick: double;
begin
  repeat
    now := GetTimer;

    if bootConfig.WaitMode = P92WaitHLT then
      nextTick := now + 1 / WaitFrequency;

    P92RunFrame;

    while GetTimer < nextTick do
    asm
      sti
      hlt
    end;
  until done;
end;

{ Perform the busy-wait loop}
procedure P92RunBusy;
var
  now, nextTick: double;
begin
  repeat
    now := GetTimer;
    nextTick := now + 1 / bootConfig.TargetFPS;

    P92RunFrame;

    while GetTimer < nextTick do ;
  until done;
end;


procedure WaitVSync;
const
  InputStatusReg1 = $3DA;
  VSyncBit = $08;
begin
  { wait for retrace to end }
  while (port[InputStatusReg1] and VSyncBit) <> 0 do;

  { wait for next retrace to begin }
  while (port[InputStatusReg1] and VSyncBit) = 0 do;
end;

{ Perform the VSync loop }
procedure P92RunVSync;
begin
  repeat
    P92RunFrame;

    if bootConfig.WaitMode = P92WaitVSync then
      WaitVSync;
  until done;
end;

{ Game engine entry point }
procedure P92Start(const config: TP92AppConfig);
begin
  bootConfig := config;

  P92Init;

{$IFDEF P92_IMGUI}
  if config.DefaultBMFont = nil then
    PanicHalt('P92Start: DefaultBMFont field is required by Immediate GUI');

  InitImmediateGUI(config.DefaultBMFont^);
{$ENDIF}

  if @config.OnPreload <> nil then
    config.OnPreload;

  if @config.OnReady <> nil then
    config.OnReady;

  if @config.DrawOnce <> nil then begin
    config.DrawOnce;
    Print('Press Enter to exit', 0, DefaultVGAHeight - 8, $0F);
    PresentMode13h;
    ResetKeyHandler;
    ReadLn;
  end else begin
    if not assigned(bootConfig.Update) then
      PanicHalt('Boot config is missing the Update method');

    if not assigned(bootConfig.Draw) then
      PanicHalt('Boot config is missing the Draw method');

    case bootConfig.WaitMode of
    P92WaitHLT:   P92RunHLT;
    P92WaitBusy:  P92RunBusy;
    P92WaitVSync: P92RunVSync;

    { Uncapped }
    else repeat P92RunFrame until done;
    end;
  end;

  if @config.OnCleanup <> nil then
    config.OnCleanup;

  P92Cleanup
end;


end.

