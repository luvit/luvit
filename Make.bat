@ECHO off

IF NOT "x%1" == "x" GOTO :%1

:luvit
ECHO "Building luvit"
SET LUVI_APP=app
SET LUVI_TARGET=luvit.exe
luvi-binaries\Windows\luvi.exe
SET "LUVI_APP="
SET "LUVI_TARGET="
GOTO :end

:test
CALL Make.bat luvit
luvit.exe tests\run.lua
GOTO :end

:clean
IF EXIST luvit.exe DEL /F /Q luvit.exe

:end
