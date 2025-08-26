set WORKSPACE=..
set LUBAN_DLL=%WORKSPACE%\Tools\Luban\Luban.dll
set GEN_DIR=%WORKSPACE%\data\gen\

dotnet %LUBAN_DLL% ^
  -t client ^
  -c cs-bin ^
  -d bin ^
  --conf .\luban.conf ^
  -x outputCodeDir=%GEN_DIR%Code ^
  -x outputDataDir=%GEN_DIR%Table

pause