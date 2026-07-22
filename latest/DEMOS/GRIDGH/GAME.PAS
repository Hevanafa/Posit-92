
uses
  CRT, DOS,
  BMFont, Logger, Keyboard, Mouse, Timing, VGA,
  Bitmap, Story;
  { Conv, FPS, Graphics, PCS; }

const
  K_ESC = $01;
  K_SPACE = $39;
var
  done: boolean;
  t: double;
  DosuEXE: array[0..1] of PBitmap;
  font: TBMFont;
  lastSpace: boolean;

  { TODO: More of your game state here }


procedure INIT;
begin
  randomize;
  initLogger;
  initVGAMode;
  loadFont;
  initBuffer;
  initDeltaTime;
  initKeyHandler;
  initMouse;

  { TODO: Your init code here }

  loadBMP(dosuEXE[0], 'IMG/DOSU_1.BMP');
  loadBMP(dosuEXE[1], 'IMG/DOSU_2.BMP');
  loadBMFont(font, 'FONTS\FGB12.FNT');
  StoryMan.init(@font);
  StoryMan.startPage(1);
  lastSpace := false;
end;


procedure update;
var
  a: integer;
begin
  updateDeltaTime;
  updateMouse;

  { TODO: Handle next page }
  if StoryMan.isStory then begin
    if lastSpace <> isKeyDown(K_SPACE) then begin
      lastSpace := isKeyDown(K_SPACE);
      if lastSpace then
        StoryMan.tryNextPage;
    end;

    StoryMan.update;
  end;

  if isKeyDown(K_ESC) then done := true;
  t:=t+dt
end;


procedure draw;
var
  a: integer;
begin
  cls($7D);

  { TODO: Your drawing code here }

  StoryMan.draw;
  StoryMan.drawDebug;

  drawMouse;

  flush
end;


var
  a: integer;

begin
  INIT;
  done := false;

  repeat
    update;
    draw;
  until done;

  { TODO: Your cleanup code here }
  freeBMP(dosuEXE[0]);
  freeBMP(dosuEXE[1]);

  resetMouse;
  resetKeyHandler;
  freeBuffer;
  closeLogger;
  initTextMode
end.
