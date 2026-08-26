unit Panic;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

procedure PanicHalt(const msg: string);

implementation

uses P92Core, P92LOG, P92KBD, P92Mouse, P92VGA;

procedure PanicHalt(const msg: string);
begin
  ResetKeyHandler;
  ResetMouse;
  InitModeText;

  WriteLn(msg);
  WriteLog('PanicHalt: ' + msg);

  CloseLogger;

  Halt(1)
end;

end.
