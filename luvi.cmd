@echo off
setlocal

set home=%~dp0
set exe=%home%luvi.exe
set bin=%home%luvi
set build=%home%make.bat
set dir=%CD%

IF NOT EXIST "%exe%" (
  cd "%home%" && CALL make && cd "%dir%"
)

IF NOT EXIST "%bin%" (
  CALL del /Q "%home%luvit" "%home%luvi" "%home%lit"
  CALL mklink "%home%luvit" "%home%luvit.exe"
  CALL mklink "%home%luvi" "%home%luvi.exe"
  CALL mklink "%home%lit" "%home%lit.exe"
)

CALL "%bin%" %*
