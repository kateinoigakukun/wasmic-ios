cmake_minimum_required(VERSION 3.17)
project(wasm3-build)
enable_language(C CXX)
set(CMAKE_CXX_STANDARD 11)

include(ExternalProject)

ExternalProject_Add(wasm3
  GIT_REPOSITORY https://github.com/wasm3/wasm3.git
  GIT_TAG        9f8766b9016aec1278e490cc5348605d2fec5fe4
  GIT_SUBMODULES_RECURSE OFF
  INSTALL_COMMAND ""
  CMAKE_GENERATOR ${CMAKE_GENERATOR}
  CMAKE_ARGS
    -D CMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -D CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -D DEPLOYMENT_TARGET=${DEPLOYMENT_TARGET}
    -D ENABLE_BITCODE=${ENABLE_BITCODE}
    -D PLATFORM=${PLATFORM}
    -D BUILD_WASI=none
    -D BUILD_NATIVE=OFF
  BUILD_COMMAND
    ${CMAKE_COMMAND} --build <BINARY_DIR> --target m3 --config $<CONFIG>)

ExternalProject_Get_property(wasm3 SOURCE_DIR)
ExternalProject_Get_property(wasm3 BINARY_DIR)

set(wasm3_headers "${SOURCE_DIR}/source/*.h")
set(wasm3_extra_headers "${SOURCE_DIR}/source/extra/wasi_core.h")

set(dummy_c ${CMAKE_CURRENT_BINARY_DIR}/dummy.c)
file(WRITE "${dummy_c}" "")

add_library(wasm3_dummy STATIC "${dummy_c}")
set_target_properties(wasm3_dummy PROPERTIES OUTPUT_NAME "wasm3")

add_custom_target(wasm3_impl.framework
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/wasm3_impl.framework
    COMMAND ${CMAKE_COMMAND} -E copy
        ${BINARY_DIR}/source/libm3.a ${CMAKE_CURRENT_BINARY_DIR}/wasm3_impl.framework/wasm3_impl
)

add_custom_target(wasm3_headers_dir
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/wasm3-headers
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/wasm3-headers/extra
    COMMAND ${CMAKE_COMMAND} -E copy ${wasm3_headers} ${CMAKE_CURRENT_BINARY_DIR}/wasm3-headers
    COMMAND ${CMAKE_COMMAND} -E copy
        ${wasm3_extra_headers} ${CMAKE_CURRENT_BINARY_DIR}/wasm3-headers/extra/
    COMMAND ${CMAKE_COMMAND} -E copy
        ${CMAKE_CURRENT_SOURCE_DIR}/include/module.modulemap ${CMAKE_CURRENT_BINARY_DIR}/wasm3-headers
)
add_dependencies(wasm3_headers_dir wasm3)

add_custom_target(wasm3.framework)
add_dependencies(wasm3_impl.framework wasm3)
add_dependencies(wasm3.framework wasm3_impl.framework wasm3_headers_dir wasm3_dummy)
