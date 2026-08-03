{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  P92Core, Bitmap, P92VGA;

var
  imgTabby: TBitmap;

procedure OnPreload; far;
begin
  LoadBMP(imgTabby, 'cat.bmp');
end;

procedure OnCleanup; far;
begin
  FreeBMP(imgTabby);
end;

procedure DrawOnce; far;
begin
  cls($7D);

  spr(imgTabby,
    (VGAWidth - imgTabby.width) div 2,
    (VGAHeight - imgTabby.height) div 2);

  SprFlipped(imgTabby, 144, 128, SprFlipHorizontal);
  SprFlipped(imgTabby, 176, 128, SprFlipVertical);
  SprFlipped(imgTabby, 208, 128, SprFlipBoth);
end;

var
  appConfig: TP92AppConfig;
begin
  DefaultP92AppConfig(appConfig);

  appConfig.EnableKeyHandler := false;
  appConfig.LoadDefaultCursor := false;

  @appConfig.OnPreload := @OnPreload;
  @appConfig.DrawOnce := @DrawOnce;
  @appConfig.OnCleanup := @OnCleanup;

  P92Start(appConfig)
end.
