call "C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" x86
msbuild /nologo /property:Configuration=Debug /target:luvit luvit.sln
