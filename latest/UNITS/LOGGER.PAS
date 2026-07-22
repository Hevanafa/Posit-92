unit Logger;

{$IFDEF FPC}
{$MODE TP}
{$ENDIF}

interface

procedure InitLogger;
procedure WriteLog(const msg: string);
procedure CloseLogger;


implementation

uses crt, dos;

var
  logFile: Text;
  logOpened: boolean;

procedure InitLogger;
begin
  assign(logFile, 'LOG.TXT');
  {$I-}
  rewrite(logFile);
  {$I+}
  logOpened := (IOResult = 0);
  if not logOpened then begin
    writeLn('Failed to create "log.txt" file!');
    readLn;
    halt
  end;
end;

procedure WriteLog(const msg: string);
begin
  if not logOpened then exit;
  writeLn(logFile, msg);
  flush(logFile)
end;

procedure CloseLogger;
begin
  if logOpened then
    close(logFile);
end;

end.
