# -----------------------------------------------------------------
# C++標準 と gRPC/Protobuf のパッケージを検索
# -----------------------------------------------------------------
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

find_package(protobuf CONFIG REQUIRED COMPONENTS gRPC)
find_package(gRPC CONFIG REQUIRED)

# gRPCプラグインとProtocのパスを取得
if(TARGET gRPC::grpc_cpp_plugin)
    get_target_property(gRPC_CPP_PLUGIN_EXECUTABLE gRPC::grpc_cpp_plugin IMPORTED_LOCATION_RELEASE)
    if(NOT gRPC_CPP_PLUGIN_EXECUTABLE)
        get_target_property(gRPC_CPP_PLUGIN_EXECUTABLE gRPC::grpc_cpp_plugin IMPORTED_LOCATION_DEBUG)
    endif()
endif()

if(TARGET protobuf::protoc)
    get_target_property(Protobuf_PROTOC_EXECUTABLE protobuf::protoc IMPORTED_LOCATION_RELEASE)
    if(NOT Protobuf_PROTOC_EXECUTABLE)
        get_target_property(Protobuf_PROTOC_EXECUTABLE protobuf::protoc IMPORTED_LOCATION_DEBUG)
    endif()
endif()

get_filename_component(PROTO_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../Protos" ABSOLUTE)
set(PROTO_FILE "${PROTO_DIR}/openpose.proto")

if(NOT EXISTS ${PROTO_FILE})
    message(FATAL_ERROR "Error: .proto file not found at: ${PROTO_FILE}\nPlease check the PROTO_DIR path in CMakeLists.txt.")
endif()

# 生成されるファイル名の定義
get_filename_component(PROTO_NAME ${PROTO_FILE} NAME_WE)
set(PROTO_SRC "${CMAKE_CURRENT_BINARY_DIR}/${PROTO_NAME}.pb.cc")
set(PROTO_HDR "${CMAKE_CURRENT_BINARY_DIR}/${PROTO_NAME}.pb.h")
set(GRPC_SRC "${CMAKE_CURRENT_BINARY_DIR}/${PROTO_NAME}.grpc.pb.cc")
set(GRPC_HDR "${CMAKE_CURRENT_BINARY_DIR}/${PROTO_NAME}.grpc.pb.h")

# -----------------------------------------------------------------
# .proto から C++ コードを生成
# -----------------------------------------------------------------
add_custom_command(
    OUTPUT ${PROTO_SRC} ${PROTO_HDR} ${GRPC_SRC} ${GRPC_HDR}
    COMMAND ${Protobuf_PROTOC_EXECUTABLE}
    ARGS --grpc_out=${CMAKE_CURRENT_BINARY_DIR}
         --cpp_out=${CMAKE_CURRENT_BINARY_DIR}
         -I ${PROTO_DIR}                                        # ←重要: .protoのあるフォルダをインクルードパスに追加
         --plugin=protoc-gen-grpc=${gRPC_CPP_PLUGIN_EXECUTABLE}
         ${PROTO_FILE}
    DEPENDS ${PROTO_FILE}
)

# OpenPose の標準ユーティリティ
include(${CMAKE_SOURCE_DIR}/cmake/Utils.cmake)

# -----------------------------------------------------------------
# 実行ファイルのビルド設定
# -----------------------------------------------------------------
set(EXAMPLE_FILES WorkerHttp_v1_0_2.cpp)

foreach(EXAMPLE_FILE ${EXAMPLE_FILES})

  get_filename_component(SOURCE_NAME ${EXAMPLE_FILE} NAME_WE)

  if (UNIX OR APPLE)
    set(EXE_NAME "${SOURCE_NAME}.bin")
  elseif (WIN32)
    set(EXE_NAME "${SOURCE_NAME}")
  endif ()

  message(STATUS "Adding Example ${EXE_NAME}")
  
  add_executable(${EXE_NAME} 
      ${EXAMPLE_FILE}
      ${PROTO_SRC}
      ${GRPC_SRC}
      ${PROTO_HDR}
      ${GRPC_HDR}
  )

  target_compile_features(${EXE_NAME} PRIVATE cxx_std_17)

  target_link_libraries(${EXE_NAME} 
      openpose 
      ${examples_3rdparty_libraries}
      gRPC::grpc++
      gRPC::grpc++_reflection
      protobuf::libprotobuf
      ws2_32
  )
  
  target_include_directories(${EXE_NAME} PUBLIC 
      ${CMAKE_CURRENT_BINARY_DIR}
  )

  if (WIN32)
    set_property(TARGET ${EXE_NAME} PROPERTY FOLDER "Examples/Tutorial/C++ API")
    configure_file(${CMAKE_SOURCE_DIR}/cmake/OpenPose${VCXPROJ_FILE_GPU_MODE}.vcxproj.user
        ${CMAKE_CURRENT_BINARY_DIR}/${EXE_NAME}.vcxproj.user @ONLY)
    set_property(TARGET ${EXE_NAME} PROPERTY RUNTIME_OUTPUT_DIRECTORY_RELEASE ${PROJECT_BINARY_DIR}/$(Platform)/$(Configuration))
    set_property(TARGET ${EXE_NAME} PROPERTY RUNTIME_OUTPUT_DIRECTORY_DEBUG ${PROJECT_BINARY_DIR}/$(Platform)/$(Configuration))
  endif (WIN32)

endforeach()