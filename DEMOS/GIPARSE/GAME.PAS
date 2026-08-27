
uses
  CRT, DOS,
  P92Core, P92LOG, P92KBD, P92VGA,
  P92STR;


procedure OnReady; far;
var
  t: text;
  line: string;
begin
  if not fileExists('GAMEINFO.TXT') then begin
    writeLn('GAMEINFO.TXT doesn''t exist!');
    halt(1)
  end;

  assign(t, 'GAMEINFO.TXT');
  reset(t);

  {
  writeLn(lower('GameInfo.TXT'));
  writeLn(upper('gameinfo.txt'));
  }

  while not eof(t) do begin
    readLn(t, line);
    { lower(line);
    writeLn(line);
    writeLn('Trimmed:');
    writeLn(trimStart(line)); }
    if startsWith(trimStart(line), 'Title') then
      WriteLog(line);
  end;

  close(t);
end;

procedure Update; far;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;
end;

procedure Draw; far;
begin
  cls($4F);

  Print('See LOG.TXT', (VgaWidth - 88) div 2, 100, 0);
end;

var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.LoadDefaultCursor := false;
  @appConfig.OnReady := @OnReady;
  @appConfig.Update := @Update;
  @appConfig.Draw := @Draw;

  P92Start(appConfig)
end.

