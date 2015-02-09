@ECHO off

IF NOT "x%1" == "x" GOTO :%1

:luvit
ECHO "Building luvit"
lit.exe make app
GOTO :end

:lit
ECHO "Building lit"
git clone --depth 1 https://github.com/luvit/luvi-binaries.git
git clone --depth 1 https://github.com/luvit/lit.git lit
SET LUVI_APP=lit-app/app
SET LUVI_TARGET=lit.exe
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
