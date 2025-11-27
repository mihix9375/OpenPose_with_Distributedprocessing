@echo off
setlocal enabledelayedexpansion
chcp 65001

for /f "tokens=1-4 delims=:.," %%a in ("%time%") do (
  set /a START=%%a*3600+%%b*60+%%c
)

winget install wget 7zip.7zip --accept-package-agreements --accept-source-agreements

type download.cache
set isdone=.\download.cache
set zpath=C:\PROGRA~1\7-zip\7z.exe 

mkdir temp
mkdir Logs

set logDir=%~dp0Logs

if "%isdone%"=="done" (
  start "" .\downloadsecondtime.bat
  exit
) 

rmdir /s /q 3rdparty\boost_1.80.0
rmdir /s /q 3rdparty\cmake-3.31.5
rmdir /s /q 3rdparty\opencv-4.9.0
rmdir /s /q 3rdparty\vcpkg

cd temp

echo Downloading ...

echo BOOST 1.80.0
wget https://archives.boost.io/release/1.80.0/source/boost_1_80_0.7z
echo Done
echo:

echo CUDA 11.8
wget https://developer.download.nvidia.com/compute/cuda/11.8.0/network_installers/cuda_11.8.0_windows_network.exe
echo Done
echo:

echo CUDNN 9.6.0
wget https://developer.download.nvidia.com/compute/cudnn/9.6.0/local_installers/cudnn_9.6.0_windows.exe
echo Done
echo:

echo CMAKE 3.31.5
wget https://cmake.org/files/v3.31/cmake-3.31.5-windows-x86_64.zip
echo Done
echo:

echo Visual Studio 2019
wget https://download.visualstudio.microsoft.com/download/pr/1192d0de-5c6d-4274-b64d-c387185e4f45/b6bf2954c37e1caf796ee06436a02c79f7b13ae99c89b8a3b3b023d64a5935e4/vs_Community.exe
echo Done
echo:

echo VCPKG
wget https://github.com/microsoft/vcpkg/archive/refs/tags/2025.10.17.zip
echo Done
echo:

echo OpenCV 4.9.0
wget https://github.com/opencv/opencv/archive/4.9.0.zip
echo Done
echo:

echo Download Done
echo:


echo Installing ...

echo Visual Studio
echo +++++++++++++++++++++++++++++++++++++++++++++++++
echo please toggle Desktop development with C++
echo +++++++++++++++++++++++++++++++++++++++++++++++++
call .\vs_Community.exe > %logDir%\visualstudio.log
echo Done
echo:

echo CUDA
call .\cuda_11.8.0_windows_network.exe > %logDir%\cuda.log
echo Done
echo:

echo cuDNN
call .\cudnn_9.6.0_windows.exe > %logDir%\cudnn.log
echo Done
echo:

echo CMAKE
%zpath% x cmake-3.31.5-windows-x86_64.zip -mmt > %logDir%\cmake.log
echo Done
echo:

echo BOOST
%zpath% x boost_1_80_0.7z -mmt > %logDir%\boost.log
cd boost_1_80_0
call .\bootstrap.bat >> %logDir%\boost.log
call b2.exe address-model=64 >> %logDir%\boost.log
cd ..
echo Done
echo:

echo VCPKG
%zpath% x 2025.10.17.zip -mmt > %logDir%\vcpkg.log
cd vcpkg-2025.10.17
call bootstrap-vcpkg.bat >> %logDir%\vcpkg.log
cd ..
move vcpkg-2025.10.17 ..\3rdparty\vcpkg
echo Done
echo:

echo GRPC
call ..\3rdparty\vcpkg\vcpkg.exe install grpc:x64-windows > %logDir%\grpc.log
echo Done
echo:

echo OpenCV
%zpath% x 4.9.0.zip -mmt > %logDir%\opencv.log
cd opencv-4.9.0
mkdir build
call ..\cmake-3.31.5-windows-x86_64\bin\cmake.exe -S . -B build -G "Visual Studio 16 2019" -DBUILD_opencv_world=ON >> %logDir%\opencv.log
cd build
call ..\..\cmake-3.31.5-windows-x86_64\bin\cmake.exe --build . --config Debug >> %logDir%\opencvd.log
call ..\..\cmake-3.31.5-windows-x86_64\bin\cmake.exe --build . --config Release >> %logDir%\opencv.log
cd ..
cd ..
echo Done
echo:

echo Install Done
echo:

echo Finishing ...

move cmake-3.31.5-windows-x86_64 ..\3rdparty\cmake-3.31.5
move boost_1_80_0 ..\3rdparty\boost_1.80.0
move opencv-4.9.0 ..\3rdparty\opencv-4.9.0

cd ..
rmdir /s /q temp

for /f "tokens=1-4 delims=:.," %%a in ("%time%") do (
  set /a END=%%a*3600+%%b*60+%%c
)
set /a DIFF=%END%-%START%
echo All Done: %DIFF% s

echo done>download.cache

pause
endlocal