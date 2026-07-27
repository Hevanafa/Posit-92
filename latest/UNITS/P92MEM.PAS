unit Memory;

interface

function GetHeapSize: longint;
function GetFreeHeap: longint;
function GetStackSize: word;
procedure DrawMemInfo;
procedure DrawDOSMemInfo;

implementation

uses DOS, Conv, VGA;

const
  { Assuming that the computer has the conventional 640 KB RAM by default }
  HeapSize = 655360;

function GetHeapSize: longint;
begin
  GetHeapSize := HeapSize
end;

function GetFreeHeap: longint;
begin
  GetFreeHeap := MemAvail
end;

{ Gets an approximate stack usage }
function GetStackSize: word;
begin
  GetStackSize := SPtr - SSeg * 16
end;

procedure DrawMemInfo;
var
  totalHeap, freeHeap: longint;
  usedPerc: single;
begin
  totalHeap := heapSize;
  freeHeap := memavail;
  usedPerc := (totalHeap - freeHeap) / totalHeap;
  
  print(
    'Heap: ' + i32str(totalHeap - freeHeap) + 'B ' +
    '/ ' + i32str(heapSize) + 'B ' + 
    '(' + i32str(round(usedPerc * 100)) + '%)', 10, 10, 15);
  print('Stack estimate: ' + i32str(GetStackSize) + 'B', 10, 40, 15)
end;

procedure DrawDOSMemInfo;
var
  Regs: Registers;
  freeMem, totalMem: longint;
begin
  { Get total conventional memory (INT 12h) }
  regs.ah := $12;
  Intr($12, regs);
  totalMem := longint(regs.ax) * 1024;
  
  print('DOS conv mem: ' + i32str(totalMem) + 'B', 10, 60, 7)
end;

end.
