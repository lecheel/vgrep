@ echo off
  if "%1"=="debug" goto Debug
  if "%1"=="de"    goto debug
  if "%1"=="dbg"   goto Debug
  if "%1"=="rel"   goto Release
  if "%1"=="cc"    goto cc
  if "%1"=="bc"    goto bc
  if "%1"=="html"  goto html
  goto Usage
  goto end
:Usage 
  Echo bind   rel     -- Release build
  echo        debug   -- Debug build
  echo        cc      -- Clear *.obj and *.exe
  goto end                  w
:cc
  if exist *.obj del /y *.obj
  if exist *.exe del /y *.exe
  if exist lcc\*.map del /y lcc\*.map
  if exist lcc\*.exe del /y lcc\*.exe
  echo clear completed.
  goto end
:bc
  if exist *.obj del /y v.obj
  make -f makefile.bc3
  goto end
:Release  
  if exist *.obj del /y v.obj
  make -f makefile
  upx lcc\vgrep.exe
  copy lcc\vgrep.exe c:\usr32
  copy lcc\vgrep.exe rel
  copy vgrep.txt rel
  goto end
:Debug
  if exist *.obj del /y v.obj
  make -f makefile.dbg
  copy lcc\vgrep.exe 
  goto end
:html
  sh -s cpp -f html --input=v.c --output=v.htm
  echo C to html convert Completed.
  goto end
:end
  echo on
  
