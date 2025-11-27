# OpenPose with Server And Worker

- Caution this project is not perfect
- This project can just output JSON files
- Can't create BVH file 

## How to build
### Server (Master)

### Client (Worker)
- Download or clone https://github.com/mihix9375/OpenPose-1.7.0-Improved/tree/main
- Marge OpenPose-1.7.0-Improved and OpenPose_with_Distributedprocessing
- Run get_3rdparty.bat
- Run workerbuild.bat


## How to use

### Server (Master)
- Download or clone this repository
- Run "get_files.cmd"
- Run "server/OpenPoseServer.exe"
- Open "http://localhost:5000" by your blowser
- Type Full-Path of video in TextBox
- Click Button "処理開始"

### Client (Worker)
- Download or clone this repository
- Run "get_files.cmd"
- Run "worker/run_worker.bat"
- Type your ip address and port
- Type Server ip address and port (Server port is 5000)
