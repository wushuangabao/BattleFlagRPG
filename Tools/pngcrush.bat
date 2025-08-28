@echo off
for /r "..\asset\png" %%x in (*.png) do (
    echo 正在处理: %%x
    pngcrush.exe -ow -rem allb -reduce "%%x"
)
echo 处理完成!
pause