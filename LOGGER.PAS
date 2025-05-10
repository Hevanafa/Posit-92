unit Logger;

interface

procedure initLogger;
procedure writeLog(const msg: string);
procedure closeLogger;


implementation

uses crt, dos;

var
  logFile: Text;
  logOpened: boolean;

procedure initLogger;
begin
  assign(logFile, 'LOG.TXT');
  {$I-}
  rewrite(logFile);
  {$I+}
  logOpened := (IOResult = 0);
  if not logOpened then
    writeLn('Failed to create "log.txt" file!')
end;

procedure writeLog(const msg: string);
begin
  if not logOpened then exit;
  writeLn(logFile, msg);
  flush(logFile)
end;

procedure closeLogger;
begin
  if logOpened then
    close(logFile);
end;

end.
