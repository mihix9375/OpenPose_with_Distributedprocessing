@echo off
cd %~dp0

set openposePATH=%CD%
set /p temp=< .\PATH.txt
set PATH=%openposePATH%\build\bin;%openposePATH%\3rdparty\opencv-4.9.0\build\x64\vc16\bin;%temp%%PATH%

chcp 65001

echo [INFO] WorkerHttp_v1.exe を起動します...
call .\build\x64\Release\WorkerHttp_v1.exe

pause