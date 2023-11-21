project(OPS2)
cmake_minimum_required(VERSION 3.4.1)

set (CMAKE_VERBOSE_MAKEFILE ON)
set (CMAKE_CXX_STANDARD 17)
set (PACKAGE_NAME "op-s2")
set (BUILD_DIR ${CMAKE_SOURCE_DIR}/build)

add_library(
  ${PACKAGE_NAME}
  SHARED
  ../cpp/logs.h
  ../cpp/macros.h
  bindings.h
  bindings.cpp
  cpp-adapter.cpp
)


include_directories(
  ../cpp
)

set_target_properties(
  ${PACKAGE_NAME} PROPERTIES
  CXX_STANDARD 17
  CXX_EXTENSIONS OFF
  POSITION_INDEPENDENT_CODE ON
)

find_package(ReactAndroid REQUIRED CONFIG)
find_package(fbjni REQUIRED CONFIG)
find_library(LOG_LIB log)

target_link_libraries(
  ${PACKAGE_NAME}
  ${LOG_LIB}
  fbjni::fbjni
  ReactAndroid::jsi
  ReactAndroid::turbomodulejsijni
  ReactAndroid::react_nativemodule_core
  android
)
