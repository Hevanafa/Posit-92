unit P92MEM;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

function GetHeapSize: longint;
function GetStackSize: word;
procedure DrawMemInfo;
procedure DrawDOSMemInfo;

implementation

uses DOS, Conv, P92VGA;

{ Assuming that the computer has the conventional 640 KB RAM by default }
const HeapSize = 655360;

function GetHeapSize: longint;
begin
  GetHeapSize := HeapSize
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
    '(' + i32str(round(usedPerc * 100)) + '%)', 10, 32, 15);

  print('Stack estimate: ' + i32str(GetStackSize) + 'B', 10, 48, 15)
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
  
  print('DOS conventional mem: ' + i32str(totalMem) + 'B', 10, 64, 7)
end;

end.
