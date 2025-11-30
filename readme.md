# OpenPose with Server And Worker

- Caution this project is not perfect
- This project can just output JSON files
- Can't create BVH file
- Please wait a moment until completion.

## Required
- Windows 10/11
- VRAM 16GB NVIDIA GPU
- 32GB RAM
- Clock 4GHz Core 8 Thread 16 CPU

## How to build
### Server (Master)
- Open "server/OpenPoseServer/OpenPoseServer.sln"
- Install NuGet package GRPC.Tools, GRPC.Net.Client, Google.Protobuf, OpenCvSharp4
- Run build

### Client (Worker)
- Download or clone https://github.com/mihix9375/OpenPose-1.7.0-Improved
- Merge OpenPose_with_Distributedprocessing to OpenPose-1.7.0-Improved
- Run "get_3rdparty.bat"
- Run "get_models.bat"
- Run "workerbuild.bat"


## How to use

### Server (Master)
- Download or clone this repository
- Run "get_files.cmd"
- Run "server/OpenPoseServer.exe"
- Open "http://localhost:5000" by your browser
- Type Full-Path of video in TextBox
- Click Button "処理開始"

### Client (Worker)
- Download or clone this repository
- Run "get_files.cmd"
- Run "worker/run_worker.bat"
- Type your ip address and port
- Type Server ip address and port (Server port is 5000)
