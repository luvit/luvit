@ECHO off
@SET GET_LIT_VERSION=3.8.1

IF NOT "x%1" == "x" GOTO :%1

:luvit
IF NOT EXIST lit.exe CALL make.bat lit
ECHO "Building luvit"
lit.exe make
if %errorlevel% neq 0 goto error
IF NOT EXIST lit CALL mklink /H lit lit.exe
if %errorlevel% neq 0 goto error
IF NOT EXIST luvi CALL mklink /H luvi luvi.exe
if %errorlevel% neq 0 goto error
IF NOT EXIST luvit CALL mklink /H luvit luvit.exe
if %errorlevel% neq 0 goto error
GOTO :end

:lit
ECHO "Building lit"
PowerShell -NoProfile -ExecutionPolicy unrestricted -Command "[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iex ((new-object net.webclient).DownloadString('https://github.com/luvit/lit/raw/%GET_LIT_VERSION%/get-lit.ps1'))"
GOTO :end

:test
IF NOT EXIST luvit.exe CALL make.bat luvit
ECHO "Testing luvit"
SET LUVI_APP=.
luvit.exe tests\run.lua
if %errorlevel% neq 0 goto error
SET "LUVI_APP="
GOTO :end

:clean
IF EXIST luvit.exe DEL /F /Q luvit.exe
IF EXIST lit.exe DEL /F /Q lit.exe

:error
exit /b %errorlevel%

:end
