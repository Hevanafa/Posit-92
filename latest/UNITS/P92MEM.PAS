{
  Memory utility unit
  Part of Posit-92 game engine

  Doesn't contain memory manager / allocator logic
}

unit P92MEM;

{$IFDEF FPC}{$MODE TP}{$ENDIF}

interface

{
Used for memory diagnostics, not called by P92Core.Init

This procedure must be called as early as possible in
the entry point / main programme block for accurate stack usage measurement
}
procedure SetStackBottom(const value: word);

{
Requires a call to SetStackBottom

Example:
SetStackBottom(word(SPtr));

The MEMVIEW demo has it
}
function GetStackSize: word;
function GetHeapSize: longint;

procedure DrawMemInfo;
procedure DrawDOSMemInfo;


implementation

uses DOS, P92CONV, P92VGA;

{ Assuming that the computer has the conventional 640 KB RAM by default }
const
  HeapSize = 655360;

var
  stackBottom: word;

procedure SetStackBottom(const value: word);
begin
  stackBottom := value
end;

function GetHeapSize: longint;
begin
  GetHeapSize := HeapSize
end;

{ Gets an approximate stack usage }
function GetStackSize: word;
begin
  GetStackSize := stackBottom - word(SPtr)
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

{ Implicit initialisation block }
begin
  stackBottom := 0;
end.

