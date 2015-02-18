@ECHO off

IF NOT "x%1" == "x" GOTO :%1

:luvit
IF NOT EXIST lit.exe CALL Make.bat lit
ECHO "Building luvit"
SET LUVI_APP=app/
SET LUVI_TARGET=luvit.exe
lit\luvi-binaries\Windows\luvi.exe
SET "LUVI_APP="
SET "LUVI_TARGET="
GOTO :end

:lit
ECHO "Building lit"
git clone --recursive --depth 10 https://github.com/luvit/lit.git lit
SET LUVI_APP=lit/
SET LUVI_TARGET=lit.exe
lit\luvi-binaries\Windows\luvi.exe
SET "LUVI_APP="
SET "LUVI_TARGET="
GOTO :end

:test
IF NOT EXIST luvit.exe CALL Make.bat luvit
SET LUVI_APP=app
luvit.exe tests\run.lua
SET "LUVI_APP="
GOTO :end

:clean
IF EXIST luvit.exe DEL /F /Q luvit.exe
IF EXIST lit.exe DEL /F /Q lit.exe
IF EXIST lit RMDIR /S /Q lit
IF EXIST luvi-binaries RMDIR /S /Q luvi-binaries

:end
