@echo off
setlocal enabledelayedexpansion
chcp 65001

set zpath=C:\PROGRA~1\7-zip\7z.exe
set logDir=%~dp0Logs

mkdir temp
mkdir Logs

for /f "tokens=1-4 delims=:.," %%a in ("%time%") do (
  set /a START=%%a*3600+%%b*60+%%c
)

:input
cls
echo Which files do you want to install?
echo 1.BOOST          
echo 2.CUDA           
echo 3.CUDNN          
echo 4.CMAKE          
echo 5.VisualStudio   
echo 6.VCPKG          
echo 7.OpenCV         
echo 8.GRPC   
echo 9.quit        
echo:
set /p installfile=:

if "%installfile%"=="9" goto :finish
if "%installfile%"=="1" goto :1
if "%installfile%"=="2" goto :2
if "%installfile%"=="3" goto :3
if "%installfile%"=="4" goto :4
if "%installfile%"=="5" goto :5
if "%installfile%"=="6" goto :6
if "%installfile%"=="7" goto :7
if "%installfile%"=="8" goto :8

echo bad input
goto :input

:1
echo Removing ...
rmdir /s /q 3rdparty\boost_1.80.0
cd temp
echo Downloading ...
wget https://archives.boost.io/release/1.80.0/source/boost_1_80_0.7z
echo:
echo Installing ...
%zpath% x boost_1_80_0.7z -mmt > %logDir%\boost.log 
cd boost_1_80_0
call .\bootstrap.bat >> %logDir%\boost.log
call b2.exe address-model=64 >> %logDir%\boost.log
cd ..
move boost_1_80_0 ..\3rdparty\boost_1.80.0
cd ..
echo Done
goto :input

:2
cd temp
echo Downloading ...
wget https://developer.download.nvidia.com/compute/cuda/11.8.0/network_installers/cuda_11.8.0_windows_network.exe
echo Installing ...
call .\cuda_11.8.0_windows_network.exe > %logDir%\cuda.log
cd ..
echo Done
goto :input

:3
cd temp
echo Downloading ...
wget https://developer.download.nvidia.com/compute/cudnn/9.6.0/local_installers/cudnn_9.6.0_windows.exe
echo Installing ...
call .\cudnn_9.6.0_windows.exe > %logDir%\cudnn.log
cd ..
echo Done
goto :input

:4
echo Removing ...
rmdir /s /q 3rdparty\cmake-3.31.5
cd temp
echo Downloading ...
wget https://cmake.org/files/v3.31/cmake-3.31.5-windows-x86_64.zip
echo Installing ...
%zpath% x cmake-3.31.5-windows-x86_64.zip -mmt > %logDir%\cmake.log
move cmake-3.31.5-windows-x86_64 ..\3rdparty\cmake-3.31.5
cd ..
echo Done
goto :input

:5
cd temp
echo Downloading ...
wget https://download.visualstudio.microsoft.com/download/pr/1192d0de-5c6d-4274-b64d-c387185e4f45/b6bf2954c37e1caf796ee06436a02c79f7b13ae99c89b8a3b3b023d64a5935e4/vs_Community.exe
echo Installing ...
echo +++++++++++++++++++++++++++++++++++++++++++++++++
echo please toggle Desktop development with C++
echo +++++++++++++++++++++++++++++++++++++++++++++++++
call .\vs_Community.exe > %logDir%\visualstudio.log
cd ..
echo Done

:6
echo Removing ...
rmdir /s /q 3rdparty\vcpkg
cd temp
echo Downloading ...
wget https://github.com/microsoft/vcpkg/archive/refs/tags/2025.10.17.zip
echo Installing ...
%zpath% x 2025.10.17.zip -mmt > %logDir%\vcpkg.log
cd vcpkg-2025.10.17
call bootstrap-vcpkg.bat >> %logDir%\vcpkg.log
cd ..
move vcpkg-2025.10.17 ..\3rdparty\vcpkg
cd ..
echo Done
goto :input

:7
echo Removing ...
rmdir /s /q 3rdparty\opencv-4.9.0
cd temp
echo Downloading ...
wget https://github.com/opencv/opencv/archive/4.9.0.zip
echo Installing ...
%zpath% x 4.9.0.zip -mmt > %logDir%\opencv.log
cd opencv-4.9.0
mkdir build
call ..\..\3rdparty\cmake-3.31.5\bin\cmake.exe -S . -B build -G "Visual Studio 16 2019" -DBUILD_opencv_world=ON >> %logDir%\opencv.log
cd build
call ..\..\..\3rdparty\cmake-3.31.5\bin\cmake.exe --build . --config Debug >> %logDir%\opencvd.log
call ..\..\..\3rdparty\cmake-3.31.5\bin\cmake.exe --build . --config Release >> %logDir%\opencv.log
cd ..
cd ..
move opencv-4.9.0 ..\3rdparty\opencv-4.9.0
cd ..
echo Done
goto :input

:8
echo Installing ...
call .\3rdparty\vcpkg\vcpkg.exe vcpkg install grpc:x64-windows > %logDir%\grpc.log
echo Done
goto :input

:finish
rmdir /s /q temp
for /f "tokens=1-4 delims=:.," %%a in ("%time%") do (
  set /a END=%%a*3600+%%b*60+%%c
)
set /a DIFF=%END%-%START%
echo All Done: %DIFF% s

pause
endlocal