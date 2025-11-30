:: -*- CODING UTF-8 -*-
@echo off

cd %~dp0

set MAIN_DIR=%~dp0

:: ======== VERSION ========
:: You can rewrite this
set CUDA_VERSION=11.8
set EIGEN_VERSION=3.4.0
:: set VS_YEARS=2019
:: set VS_VERSION=16
set BOOST_VERSION=1.80.0
set OPENCV_VERSION=4.9.0
set CMAKE_VERSION=3.31.5
:: set NSIGHT_SYSTEM_VERSION=2019.5.2
:: set NSIGHT_COMPUTE_VERSION=2019.5.0
:: set WINWDOWS_SDK_VERSION=
:: =========================

:: set /p isInstalllCUDA=Did You install CUDA? (If "n", CUDA 11.8 is used)[y/n]:

:: if not "%isInstalllCUDA%" == "n" (
:: 	 goto :cuda_skip
:: )
:: ======== CUDA ========
:: set CUDA_PATH=%~dp03rdparty/CUDA-%CUDA_VERSION%
:: set CUDA_PATH_BIN=%CUDA_PATH%/bin
:: set CUDA_PATH_LIB_NVVP=%CUDA_PATH%/libnvvp
:: set CUDA_EXTRAS_PATH=%CUDA_PATH%/extras
:: set CMAKE_CUDA_COMPILER=H%CUDA_PATH%/bin/nvcc.exe
:: set CUDAToolkit_ROOT=%CUDA_PATH%
:: set CUDA_SDK_ROOT_DIR=%CUDA_PATH%
:: set CUDA_TOOLKIT_ROOT_DIR=%CUDA_PATH%
:: set CUDA_INCLUDE_DIRS=%CUDA_PATH%/include
set CMAKE_CUDA_ARCHITECTURES=64
:: set CUDA_DIR=%CUDA_PATH%
set CMAKE_CUDA_FLAGS=-allow-unsupported-compiler
:: ====================== 

:cuda_skip

:: ======== BOOST ========
set BOOST_PATH=%~dp03rdparty/boost_%BOOST_VERSION%
set BOOST_ROOT=%BOOST_PATH%
set Boost_INCLUDE_DIR=%BOOST_PATH%
set Boost_LIBRARY_DIR=%BOOST_PATH%/stage/lib
set Boost_DIR=%BOOST_PATH%/stage/lib/cmake/Boost-%BOOST_VERSION%
:: =======================

:: ======== OPENCV ========
set OpenCV_INCLUDE_DIR=%~dp03rdparty/opencv-%OPENCV_VERSION%/build/include
set OpenCV_DIR=%~dp03rdparty/opencv-%OPENCV_VERSION%/build
set OpenCV_LIB_DIR=%~dp03rdparty/opencv-%OPENCV_VERSION%/build/lib
set OpenCV_LIBS_DEBUG_DIR=%~dp03rdparty/opencv-%OPENCV_VERSION%/build/lib/Debug
set OpenCV_LIBS_RELEASE_DIR=%~dp03rdparty/opencv-%OPENCV_VERSION%/build/lib/Release
set OpenCV_LIBS_DEBUG=%~dp03rdparty/opencv-%OPENCV_VERSION%/build/lib/Debug/opencv_world490d.lib
set OpenCV_LIBS_RELEASE=%~dp03rdparty/opencv-%OPENCV_VERSION%/build/lib/Release/opencv_world490.lib
:: set OpenCV_LIB_DIR=%~dp03rdparty/opencv-%OPENCV_VERSION%/build/x64/vc16/lib
:: set OpenCV_LIBS_DEBUG_DIR=%~dp03rdparty/opencv-%OPENCV_VERSION%/build/x64/vc16/lib
:: set OpenCV_LIBS_RELEASE_DIR=%~dp03rdparty/opencv-%OPENCV_VERSION%/build/x64/vc16/lib
:: set OpenCV_LIBS_DEBUG=%~dp03rdparty/opencv-%OPENCV_VERSION%/build/x64/vc16/lib/opencv_world490d.lib
:: set OpenCV_LIBS_RELEASE=%~dp03rdparty/opencv-%OPENCV_VERSION%/build/x64/vc16/lib/opencv_world490.lib
:: if OPENCV_VERSION == "4.9.0" (
::	set OpenCV_DIR=%~dp03rdparty/opencv-%OPENCV_VERSION%/build
::	set OpenCV_LIB_DIR=%~dp03rdparty/opencv-%OPENCV_VERSION%/build/x64/vc16/lib
::	set OpenCV_LIBS_DEBUG=%~dp03rdparty/opencv-4.9.0/build/x64/vc16/lib
::	set OpenCV_LIBS_RELEASE=%~dp03rdparty/opencv-4.9.0/build/x64/vc16/lib
::) else (
::	set OpenCV_DIR=%~dp03rdparty/opencv-%OPENCV_VERSION%/build
::	set OpenCV_LIB_DIR=%~dp03rdparty/opencv-%OPENCV_VERSION%/build/install/x64/vc16/lib
::	set OpenCV_LIBS_DEBUG=%~dp03rdparty/opencv-%OPENCV_VERSION%/build/install/x64/vc16/lib/opencv_core4100d.lib
::	set OpenCV_LIBS_RELEASE=%~dp03rdparty/opencv-%OPENCV_VERSION%/build/install/x64/vc16/lib/opencv_core4100d.lib
::)
:: ========================

:: ======== GRPC ========
set GRPC_INSTALL_DIR=%~dp03rdparty/vcpkg/installed/x64-windows/
set Protobuf_LIBRARY=%~dp03rdparty/vcpkg/installed/x64-windows/lib
set Protobuf_DIR=%~dp03rdparty/vcpkg/installed/x64-windows/share/protobuf
:: ======================

:: ======== EIGEN ========
set EIGEN_PATH=%~dp03rdparty/eigen-%EIGEN_VERSION%
set Eigen_ROOT=%~dp03rdparty/eigen-%EIGEN_VERSION%
set EIGEN_INCLUDE_DIR=%~dp03rdparty/eigen-%EIGEN_VERSION%
:: =======================

:: ======== CMAKE ========
set CMAKE_ROOT=%~dp03rdparty/cmake-%CMAKE_VERSION%/build
set CMAKE_MODULE_PATH=%CMAKE_MODULE_PATH%;%~dp03rdparty/boost_%BOOST_VERSION%/tools/cmake/config;%~dp03rdparty/boost_%BOOST_VERSION%/tools/cmake/include;%~dp03rdparty/cmake-%CMAKE_VERSION%/Modules;%~dp03rdparty\grpc\cmake;%CUDA_PATH%;%~dp03rdparty\eigen-3.3.9\cmake
set CMAKE_PREFIX_PATH=%CUDA_PATH%;%BOOST_PATH%;%~dp03rdparty/cmake-%CMAKE_VERSION%/Modules;%GRPC_INSTALL_DIR%;%EIGEN_PATH%;%Eigen_ROOT%;%CMAKE_PREFIX_PATH%
:: ==============================

:: ======== VISUAL_STUDIO ========
:: set VS140COMNTOOLS=%~dp03rdparty/Visual_Studio_%VS_YEARS%/Common7/tools
:: ===============================

:: ======== PATH ========
set PATH=%CUDA_PATH%;%CUDA_PATH_LIB_NVVP%;%~dp03rdparty/Nsight_Systems_%NSIGHT_SYSTEM_VERSION%;%~dp03rdparty/cmake-%CMAKE_VERSION%/build/bin;%~dp03rdparty/Visual_Studio_%VS_YEARS%/Common7/IDE;%~dp03rdparty/Nsight_Compute_%NSIGHT_COMPUTE_VERSION%;%OpenCV_DIR%\bin;%~dp03rdparty\Visual_Studio_2019\VC\Tools\MSVC\14.29.30133\bin\Hostx64\x64;%PATH%
call %~dp03rdparty/Visual_Studio_%VS_YEARS%/VC/Auxiliary/Build/vcvars64.bat
:: ======================

:: ======== RESET_BUILD ========
del /s /f /q .\build
del PATH.txt

rmdir build /s /q

mkdir build
:: =============================

%~dp03rdparty\cmake-%CMAKE_VERSION%\bin\cmake.exe --version

echo CUDA version %CUDA_VERSION%
echo VS year %VS_YEARS%
echo VS version %VS_VERSION%
echo BOOST version %BOOST_VERSION%
echo OPENCV version%OPENCV_VERSION%
echo CMAKE version %CMAKE_VERSION%
echo NSIGHT SYSTEM version %NSIGHT_SYSTEM_VERSION%
echo NSIGHT COMPUTE version %NSIGHT_COMPUTE_VERSION%
echo WINDOWS SDK version %WINWDOWS_SDK_VERSION%
echo PATH %PATH%

:: ======== CONFIGURE ========
:: "Visual Studio [VS_VERSION] [VS_YEARS]"
%~dp03rdparty\cmake-%CMAKE_VERSION%\bin\cmake.exe -DCMAKE_PREFIX_PATH=%CMAKE_PREFIX_PATH% -DWITH_EIGEN=FIND -G "Visual Studio 16 2019" -A x64 -Wno-dev -S . -B ./build
:: ===========================

cd build

:: ======== BUILD ========
%~dp03rdparty\cmake-%CMAKE_VERSION%\bin\cmake.exe --build . --config Release
:: =======================

cd ..

:: set temp=%CUDA_PATH%;%CUDA_PATH_LIB_NVVP%;%~dp03rdparty/Nsight_Systems_%NSIGHT_SYSTEM_VERSION%;%~dp03rdparty/cmake-%CMAKE_VERSION%/build/bin;%~dp03rdparty/Visual_Studio_%VS_YEARS%/Common7/IDE;%~dp03rdparty/Nsight_Compute_%NSIGHT_COMPUTE_VERSION%;%OpenCV_DIR%\bin;

:: echo %temp% >> PATH.txt

pause
