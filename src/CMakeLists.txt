cmake_minimum_required(VERSION 2.6)
project(predatorprey)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

# Set compiler flags
set(CMAKE_CXX_FLAGS "-Wall -Wextra")
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

# Find Lua
find_package(Lua REQUIRED)
include_directories(${LUA_INCLUDE_DIR})

# Set PKG_CONFIG_PATH
set(ENV{PKG_CONFIG_PATH} "/home/edgardo/argos3/build:/home/edgardo/argos3-dist/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}")

# Check for ARGoS3
find_package(PkgConfig REQUIRED)
pkg_check_modules(ARGOS REQUIRED IMPORTED_TARGET argos3_simulator)

# Add ARGoS paths
include_directories(${ARGOS_INCLUDE_DIRS})
link_directories(${ARGOS_LIBRARY_DIRS})

# Create the loop function library
add_library(predatorprey SHARED predatorprey.h predatorprey.cpp)
target_link_libraries(predatorprey
  PRIVATE
  ${LUA_LIBRARIES}
  PkgConfig::ARGOS
  argos3plugin_simulator_entities
  argos3plugin_simulator_footbot
  argos3plugin_simulator_media)
