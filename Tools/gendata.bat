set WORKSPACE=..
set LUBAN_DLL=%WORKSPACE%\Tools\Luban\Luban.dll
set CODE_DIR=%WORKSPACE%\modules\luban\Code

dotnet %LUBAN_DLL% ^
  -t client ^
  -c cpp-sharedptr-bin ^
  -d bin ^
  --conf %WORKSPACE%\luban.conf ^
  -x outputCodeDir=%CODE_DIR% ^
  -x outputDataDir=%WORKSPACE%\modules\luban\Table

powershell -Command "$content = Get-Content '%CODE_DIR%\schema.h' -Encoding UTF8; $content[13] = '#include \"../CfgBean.h\"'; Set-Content '%CODE_DIR%\schema.h' -Value $content -Encoding UTF8"

pause