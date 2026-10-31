cmake_minimum_required(VERSION 3.31...4.4)

# `nix flake init` cannot substitute a name: rename `app` here.
# C only: drop CXX here, and the CMAKE_CXX_ lines below.
project(app VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF) # on by default for C++20 and later

add_compile_options(-Wall -Wextra -Wpedantic)

# Set by the asan and tsan presets. Applies to every target below.
set(SANITIZE "" CACHE STRING "Value for -fsanitize=, e.g. address,undefined")
if(SANITIZE)
  add_compile_options(-fsanitize=${SANITIZE} -fno-sanitize-recover=all)
  add_link_options(-fsanitize=${SANITIZE})
endif()

add_library(core src/add.c)
target_include_directories(core PUBLIC include)

add_executable(app src/main.cpp)
target_link_libraries(app PRIVATE core)

include(CTest)
if(BUILD_TESTING)
  add_executable(test_add tests/test_add.c)
  target_link_libraries(test_add PRIVATE core)
  add_test(NAME test_add COMMAND test_add)
endif()
