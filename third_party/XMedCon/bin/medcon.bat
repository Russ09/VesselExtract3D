@echo off

REM define where XMEDCON was installed (no quotes, please)
set XMEDCONDIR=C:\Program Files\XMedCon

REM any other environment variables derived
set XMEDCONLUT=%XMEDCONDIR%\etc\
set XMEDCONRC=%XMEDCONDIR%\etc\xmedconrc
set PATH=%XMEDCONDIR%\BIN;%XMEDCONDIR%\LIB;%PATH%

medcon.exe
