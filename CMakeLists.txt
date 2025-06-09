cmake_minimum_required(VERSION 3.10)
project(hpc_lvgl)

cmake_policy(SET CMP0079 NEW)

find_package(PkgConfig REQUIRED)
pkg_check_modules(SDL2 REQUIRED sdl2)
pkg_check_modules(SDL2_IMAGE REQUIRED SDL2_image)

set(CMAKE_C_STANDARD 99) # LVGL officially supports C99 and above
set(CMAKE_CXX_STANDARD 17) # C17
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra -Wpedantic -g")

# set(LV_BUILD_SET_CONFIG_OPTS ON CACHE BOOL "create CMAKE variables from
# lv_conf_internal.h" FORCE)

include(ExternalProject)
ExternalProject_Add(
  lvgl_cache
  GIT_REPOSITORY https://github.com/lvgl/lvgl.git
  GIT_TAG d5149c39065473a6117793492e11b8372dc8ab14
  PREFIX ${CMAKE_BINARY_DIR}/lvgl_cache
  CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/lvgl_cache_install
             -DLV_BUILD_CONF_PATH=${CMAKE_SOURCE_DIR}/lv_conf_cache.h
             -DLV_BUILD_SET_CONFIG_OPTS=1
  BUILD_ALWAYS FALSE)
ExternalProject_Add(
  lvgl_no_cache
  GIT_REPOSITORY https://github.com/lvgl/lvgl.git
  GIT_TAG d5149c39065473a6117793492e11b8372dc8ab14
  PREFIX ${CMAKE_BINARY_DIR}/lvgl_no_cache
  CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/lvgl_no_cache_install
             -DLV_BUILD_CONF_PATH=${CMAKE_SOURCE_DIR}/lv_conf_no_cache.h
             -DLV_BUILD_SET_CONFIG_OPTS=1
  BUILD_ALWAYS FALSE)

ExternalProject_Get_Property(lvgl_cache SOURCE_DIR)
set(LVGL_CACHE_SOURCE_DIR ${SOURCE_DIR})

ExternalProject_Get_Property(lvgl_no_cache SOURCE_DIR)
set(LVGL_NO_CACHE_SOURCE_DIR ${SOURCE_DIR})

set(SRC_FILES src/main.c)
set(LIBS ${SDL2_LIBRARIES} ${SDL2_IMAGE_LIBRARIES} m)

add_executable(tiny_ttf_demo_no_cache ${SRC_FILES})
add_executable(tiny_ttf_demo_cache ${SRC_FILES})

target_link_libraries(
  tiny_ttf_demo_no_cache
  ${CMAKE_BINARY_DIR}/lvgl_no_cache_install/lib/liblvgl.a ${LIBS})
target_link_libraries(
  tiny_ttf_demo_cache ${CMAKE_BINARY_DIR}/lvgl_cache_install/lib/liblvgl.a
  ${LIBS})

target_compile_definitions(
  tiny_ttf_demo_no_cache
  PRIVATE -DLV_CONF_PATH="${CMAKE_SOURCE_DIR}/lv_conf_no_cache.h")

target_compile_definitions(
  tiny_ttf_demo_cache
  PRIVATE -DLV_CONF_PATH="${CMAKE_SOURCE_DIR}/lv_conf_cache.h")
target_include_directories(tiny_ttf_demo_no_cache
                           PRIVATE ${LVGL_NO_CACHE_SOURCE_DIR})
target_include_directories(tiny_ttf_demo_cache PRIVATE ${LVGL_CACHE_SOURCE_DIR})

target_compile_options(tiny_ttf_demo_no_cache PRIVATE -Wall -Wextra -pedantic
                                                      -g)
target_compile_options(tiny_ttf_demo_cache PRIVATE -Wall -Wextra -pedantic -g)

add_dependencies(tiny_ttf_demo_no_cache lvgl_no_cache)
add_dependencies(tiny_ttf_demo_cache lvgl_cache)
