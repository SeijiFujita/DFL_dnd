@echo off 
@rem set path=C:\D\dmd.2.065.0\windows\bin;C:\D\dm\bin;
set path=C:\D\dmd.2.066.0\windows\bin;C:\D\dm\bin;

@echo on


dmd dndTest.d -g -I./dfl -version=DFL_UNICODE ./dfl/dfl_debug.lib -L/exet:nt/su:windows:4.0

dmd drop.d -g -I./dfl -version=DFL_UNICODE ./dfl/dfl_debug.lib -L/exet:nt/su:windows:4.0

dmd droplist.d -g -I./dfl -version=DFL_UNICODE ./dfl/dfl_debug.lib -L/exet:nt/su:windows:4.0

@echo off
if NOT ERRORLEVEL 1 GOTO Run
goto End
rem -------------------
:Run

rem dndTest.exe
del *.obj

rem -------------------
goto End:



:End



