
uses
  P92Core, P92VGA;

procedure DrawOnce; far;
begin

end;

var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.LoadDefaultCursor := false;

  { @appConfig.OnPreload := @OnPreload;
  @appConfig.OnReady := @OnReady; }
  { @appConfig.Update := @Update;
  @appConfig.Draw := @Draw; }
  @appConfig.DrawOnce := @DrawOnce;
  { @appConfig.OnCleanup := @OnCleanup; }

  P92Start(appConfig)
end.

