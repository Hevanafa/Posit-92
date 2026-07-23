{
Command line:
E:\fpc-go32v2-i386\fpc\bin\x86_64-win64\fpc.exe -Tgo32v2 -Pi386 -FuE:\fpc-go32v2-i386\fpcsrc\rtl\units\go32v2 -FuE:\fpc-go32v2-i386\fpcsrc\packages\rtl-console\units\go32v2 .\MAIN.PAS

It's recommended to edit fpc.cfg

Something like:
#ifdef go32v2
-FuE:\fpc-go32v2-i386\fpcsrc\rtl\units\go32v2
-FuE:\fpc-go32v2-i386\fpcsrc\packages\rtl-console\units\go32v2
#endif

However, using Lazarus IDE is easier

1. Project menu > Project options
2. Scroll down to Compiler Options
3. Click Paths
4. In other unit files (-Fu), add these two paths:

```
E:\fpc-go32v2-i386\fpcsrc\rtl\units\go32v2
E:\fpc-go32v2-i386\fpcsrc\packages\rtl-console\units\go32v2
```

Use Shift+F9 to build only, and then run the EXE manually with DOSBox-X
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

