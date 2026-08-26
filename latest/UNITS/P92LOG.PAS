unit P92LOG;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

procedure InitLogger;
procedure WriteLog(const msg: string);
procedure CloseLogger;


implementation

uses CRT, DOS;

var
  logFile: Text;
  isLogOpened: boolean;

procedure InitLogger;
begin
  assign(logFile, 'LOG.TXT');
  {$I-}
  rewrite(logFile);
  {$I+}

  isLogOpened := (IOResult = 0);
  if not isLogOpened then begin
    writeLn('Failed to create "log.txt" file!');
    readLn;
    halt
  end;
end;

procedure WriteLog(const msg: string);
begin
  if not isLogOpened then exit;
  writeLn(logFile, msg);
  flush(logFile)
end;

procedure CloseLogger;
begin
  if isLogOpened then
    close(logFile);
end;

end.
