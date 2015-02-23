@ECHO off

IF NOT "x%1" == "x" GOTO :%1

:luvit
IF NOT EXIST lit.exe CALL Make.bat lit
ECHO "Building luvit"
lit.exe make
GOTO :end

:lit
ECHO "Building lit"
PowerShell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://github.com/luvit/lit/raw/0.9.8/web-install.ps1'))"
IF EXIST lit.zip DEL /F /Q lit.zip
GOTO :end

:test
IF NOT EXIST luvit.exe CALL Make.bat luvit
ECHO "Testing luvit"
SET LUVI_APP=.
luvit.exe tests\run.lua
SET "LUVI_APP="
GOTO :end

:clean
IF EXIST luvit.exe DEL /F /Q luvit.exe
IF EXIST lit.exe DEL /F /Q lit.exe

:end
