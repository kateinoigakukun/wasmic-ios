cmake_minimum_required(VERSION 3.17)
project(wabt-c-api)
enable_language(C CXX)
set(CMAKE_CXX_STANDARD 11)

include(ExternalProject)

ExternalProject_Add(wabt
  GIT_REPOSITORY https://github.com/WebAssembly/wabt.git
  GIT_TAG        1.0.23
  GIT_SUBMODULES_RECURSE OFF
  INSTALL_COMMAND ""
  CMAKE_GENERATOR ${CMAKE_GENERATOR}
  CMAKE_ARGS
    -D CMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -D DEPLOYMENT_TARGET=${DEPLOYMENT_TARGET}
    -D ENABLE_BITCODE=${ENABLE_BITCODE}
    -D PLATFORM=${PLATFORM}
    -D BUILD_TESTS=OFF
  BUILD_COMMAND
    ${CMAKE_COMMAND} --build <BINARY_DIR> --target wabt --config $<CONFIG>)

add_library(wabt-c-api
    lib/wabt-c-api.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/include/wabt-c-api.h)

ExternalProject_Get_property(wabt SOURCE_DIR)
ExternalProject_Get_property(wabt BINARY_DIR)
target_include_directories(wabt-c-api
    PRIVATE
        ${SOURCE_DIR}
        ${BINARY_DIR})
add_dependencies(wabt-c-api wabt)

find_program(LLVM_AR NAMES llvm-ar)

set(wabt_mri ${CMAKE_CURRENT_BINARY_DIR}/wabt.mri)
file(WRITE "${wabt_mri}"
    "create ${CMAKE_CURRENT_BINARY_DIR}/libwabt.a\n"
    "addlib ${BINARY_DIR}/libwabt.a\n"
    "addlib ${CMAKE_CURRENT_BINARY_DIR}/libwabt-c-api.a\n"
    "save\n"
    "end\n"
)

add_custom_target(wabt.framework
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/wabt.framework
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/wabt.framework/Headers
    COMMAND ${CMAKE_COMMAND} -E copy
        ${CMAKE_CURRENT_SOURCE_DIR}/include/wabt-c-api.h ${CMAKE_CURRENT_BINARY_DIR}/wabt.framework/Headers
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/wabt.framework/Modules
    COMMAND ${CMAKE_COMMAND} -E copy
        ${CMAKE_CURRENT_SOURCE_DIR}/include/module.modulemap ${CMAKE_CURRENT_BINARY_DIR}/wabt.framework/Modules
    COMMAND cat "${wabt_mri}" | ${LLVM_AR} -M
    COMMAND ${CMAKE_COMMAND} -E copy
        ${CMAKE_CURRENT_BINARY_DIR}/libwabt.a ${CMAKE_CURRENT_BINARY_DIR}/wabt.framework/wabt
)

add_dependencies(wabt.framework wabt-c-api)
