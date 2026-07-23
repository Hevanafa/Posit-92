{
E:\fpc-go32v2-i386\fpc\bin\x86_64-win64\fpc.exe -Tgo32v2 -Pi386 -FuE:\fpc-go32v2-i386\fpcsrc\rtl\units\go32v2 -FuE:\fpc-go32v2-i386\fpcsrc\packages\rtl-console\units\go32v2 .\MAIN.PAS

It's recommended to edit fpc.cfg

Something like:
#ifdef go32v2
-FuE:\fpc-go32v2-i386\fpcsrc\rtl\units\go32v2
-FuE:\fpc-go32v2-i386\fpcsrc\packages\rtl-console\units\go32v2
#endif
}

program Project;

uses CRT, DOS;

var
  h, m, s, ms: word;
begin
  ClrScr;

  TextColor(yellow);
  gettime(h, m, s, ms);
  writeln('DOS time: ', h, ':', m, ':', s);

  writeln('Press Enter to continue');

  readln
end.

