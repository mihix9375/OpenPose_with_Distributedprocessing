# -----------------------------------------------------------------
# C++標準 と gRPC/Protobuf のパッケージを検索
# -----------------------------------------------------------------
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# vcpkg などで CMAKE_TOOLCHAIN_FILE が指定されていれば、
# find_package が gRPC と Protobuf を見つけます
find_package(Protobuf CONFIG REQUIRED COMPONENTS gRPC)
find_package(gRPC CONFIG REQUIRED)

# -----------------------------------------------------------------
# ビルド対象ファイル と Proto定義
# -----------------------------------------------------------------

# ビルドする実行ファイルを指定 (元のリストを置き換え)
set(EXAMPLE_FILES
    WorkerHttp_v1_0_2.cpp
)

# .proto ファイルの場所を指定 (環境に合わせて要調整)
set(PROTO_DIR ${CMAKE_SOURCE_DIR}/../../Protos)
set(PROTO_FILE ${PROTO_DIR}/openpose.proto)

# .proto から生成される .cpp/.h ファイルの出力先
set(PROTO_GENERATED_DIR ${CMAKE_CURRENT_BINARY_DIR}/generated)

# -----------------------------------------------------------------
# .proto から C++ コードを生成する設定
# -----------------------------------------------------------------
protobuf_generate_grpc(
    TARGET WorkerHttp_v1_0_2_proto
    LANGUAGE cpp
    PROTOS ${PROTO_FILE}
    IMPORT_DIRS ${PROTO_DIR}
    GENERATE_MOCKS FALSE
    # PROTO_SRCS という変数に、生成されたファイルパスが格納される
    GENERATED_FILES_VAR PROTO_SRCS 
)

# OpenPose の標準ユーティリティをインクルード
include(${CMAKE_SOURCE_DIR}/cmake/Utils.cmake)

# -----------------------------------------------------------------
# 実行ファイルのビルド設定 (ループ)
# -----------------------------------------------------------------
# (EXAMPLE_FILES には WorkerHttp_v1_0_2.cpp しか入っていない)
foreach(EXAMPLE_FILE ${EXAMPLE_FILES})

  get_filename_component(SOURCE_NAME ${EXAMPLE_FILE} NAME_WE)

  # 実行ファイル名 (Win: .exe, Linux: .bin)
  if (UNIX OR APPLE)
    set(EXE_NAME "${SOURCE_NAME}.bin")
  elseif (WIN32)
    set(EXE_NAME "${SOURCE_NAME}")
  endif ()

  message(STATUS "Adding Example ${EXE_NAME}")
  
  # 実行ファイル(ターゲット)を追加
  add_executable(${EXE_NAME} 
      ${EXAMPLE_FILE}  # WorkerHttp_v1_0_2.cpp
      ${PROTO_SRCS}    # openpose.pb.cc と openpose.grpc.pb.cc
  )

  # C++17 をターゲットに設定
  target_compile_features(${EXE_NAME} PRIVATE cxx_std_17)

  # 必要なライブラリをすべてリンク
  target_link_libraries(${EXE_NAME} 
      # OpenPose 本体
      openpose 
      ${examples_3rdparty_libraries} # OpenCV, Caffe など
      
      # gRPC と Protobuf のライブラリ
      gRPC::grpc++
      gRPC::grpc++_reflection
      Protobuf::libprotobuf

      # Winsock (C++コード内で #pragma しているが、CMakeでも明示)
      ws2_32
  )
  
  # .proto から生成された .h ファイルを見つけるためのインクルードパス
  target_include_directories(${EXE_NAME} PRIVATE 
      ${PROTO_GENERATED_DIR}
  )

  # Visual Studio の .vcxproj.user などを設定 (元のまま)
  if (WIN32)
    set_property(TARGET ${EXE_NAME} PROPERTY FOLDER "Examples/Tutorial/C++ API")
    configure_file(${CMAKE_SOURCE_DIR}/cmake/OpenPose${VCXPROJ_FILE_GPU_MODE}.vcxproj.user
        ${CMAKE_CURRENT_BINARY_DIR}/${EXE_NAME}.vcxproj.user @ONLY)
    # Properties->General->Output Directory
    set_property(TARGET ${EXE_NAME} PROPERTY RUNTIME_OUTPUT_DIRECTORY_RELEASE ${PROJECT_BINARY_DIR}/$(Platform)/$(Configuration))
    set_property(TARGET ${EXE_NAME} PROPERTY RUNTIME_OUTPUT_DIRECTORY_DEBUG ${PROJECT_BINARY_DIR}/$(Platform)/$(Configuration))
  endif (WIN32)

endforeach()