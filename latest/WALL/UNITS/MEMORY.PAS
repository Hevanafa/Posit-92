unit Memory;

interface

function getHeapSize: longint;
function getFreeHeap: longint;
function getStackSize: word;
procedure drawMemInfo;
procedure drawDOSMemInfo;

implementation

uses DOS, Conv, VGA;

const
  HeapSize = 655360;

function getHeapSize: longint;
begin
  getHeapSize := HeapSize
end;

function getFreeHeap: longint;
begin
  getFreeHeap := MemAvail
end;

function getStackSize: word;
begin
  { approximate stack usage }
  getStackSize := sptr - sseg * 16
end;

procedure drawMemInfo;
var
  totalHeap, freeHeap: longint;
  usedPerc: single;
begin
  totalHeap := heapSize;
  freeHeap := memavail;
  usedPerc := (totalHeap - freeHeap) / totalHeap;
  
  print('Heap: ' + i32str(totalHeap - freeHeap) + 'B ' + 
    '/ ' + i32str(heapSize) + 'B ' + 
	'( ' + i32str(round(usedPerc)) + '%)', 10, 10, 15);
  print('Stack estimate: ' + i32str(getStackSize) + 'B', 10, 40, 15)
end;

procedure drawDOSMemInfo;
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
