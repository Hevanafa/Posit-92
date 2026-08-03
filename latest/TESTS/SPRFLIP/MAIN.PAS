{$IFDEF FPC}{$MODE TP}{$ENDIF}

uses
  P92Core, Bitmap, Conv, Graphics, Timing, P92VGA;

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
var
  startTick: double;
  a: integer;
  s: string;
begin
{ Singular sprites }
{
  cls($7D);

  spr(imgTabby,
    (VGAWidth - imgTabby.width) div 2,
    (VGAHeight - imgTabby.height) div 2);

  SprFlipped(imgTabby, 144, 128, SprFlipHorizontal);
  SprFlipped(imgTabby, 176, 128, SprFlipVertical);
  SprFlipped(imgTabby, 208, 128, SprFlipBoth);
}

  { Benchmark }
  cls($00);
  startTick := GetTimer;

  for a:=1 to 1000 do begin
    { Original: 2.3945s
      After row-level opt: 1.6550s }
    { SprFlipped(imgTabby, random(VGAWidth + 20) - 40, random(VGAHeight + 20) - 40, SprFlipHorizontal); }

    { Original: 2.3968s
      After row-level opt: 1.6557s }
    SprFlipped(imgTabby, random(VGAWidth + 20) - 40, random(VGAHeight + 20) - 40, SprFlipVertical);
  end;

  s := '1000 operations done in ' + F32Str(GetTimer - startTick) + 's';
  rectfill(0, VGAHeight - 16, Length(s) * 8 - 1, VGAHeight - 9, 0);
  Print(s, 0, VGAHeight - 16, $0F)
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
