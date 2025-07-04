unit BMPRLE;

interface

type
  PRLEBitmap = ^TRLEBitmap;
  TRLEBitmap = record
    width, height: word;
    dataSize: word;
    data: array[0..0] of byte;
  end;

implementation

end.