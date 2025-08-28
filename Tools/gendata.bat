set WORKSPACE=..
set LUBAN_DLL=%WORKSPACE%\Tools\Luban\Luban.dll

dotnet %LUBAN_DLL% ^
  -t client ^
  -c cs-bin ^
  -d bin ^
  --conf %WORKSPACE%\luban.conf ^
  -x outputCodeDir=%WORKSPACE%\luban\Code ^
  -x outputDataDir=%WORKSPACE%\luban\Table

pause