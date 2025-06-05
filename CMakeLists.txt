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

# function(create_lvgl_target TARGET_NAME CONFIG_FILE)
#
# file(GLOB_RECURSE SOURCES lvgl/src/*.c lvgl/src/*.S) file(GLOB_RECURSE
# DEMO_SOURCES lvgl/demos/*.c)
#
# add_library(${TARGET_NAME} STATIC ${SOURCES} ${DEMO_SOURCES})
#
# target_compile_definitions(${TARGET_NAME} PRIVATE
# -DLV_CONF_PATH="${CMAKE_CURRENT_SOURCE_DIR}/${CONFIG_FILE}")
#
# target_include_directories(${TARGET_NAME} PUBLIC lvgl/src
# ${CMAKE_CURRENT_SOURCE_DIR} ) endfunction()
#
# Render test executable create_lvgl_target(lvgl_render "lv_conf_render.h")
# Uncomment if the program needs debugging set(CMAKE_BUILD_TYPE Debug)
# target_include_directories(lvgl_render PUBLIC lvgl)
# target_link_libraries(lvgl_render PUBLIC) add_executable(render src/render.c)
# target_link_libraries(render lvgl_render) target_compile_definitions( render
# PRIVATE LV_CONF_PATH="${CMAKE_CURRENT_SOURCE_DIR}/lv_conf_render.h" )
#
# Benchmark with software rendering create_lvgl_target(lvgl_benchmark_sw
# "lv_conf_benchmark_sw.h") target_link_libraries(lvgl_benchmark_sw PUBLIC
# ${SDL2_LIBRARIES} ${SDL2_IMAGE_LIBRARIES})
# target_include_directories(lvgl_benchmark_sw PUBLIC lvgl)
# add_executable(benchmark_sw src/benchmark.c)
# target_link_libraries(benchmark_sw lvgl_benchmark_sw)
# target_compile_definitions( benchmark_sw PRIVATE
# LV_CONF_PATH="${CMAKE_CURRENT_SOURCE_DIR}/lv_conf_benchmark_sw.h" )
#
# Benchmark with neon rendering create_lvgl_target(lvgl_benchmark_neon
# "lv_conf_benchmark_neon.h") target_link_libraries(lvgl_benchmark_neon PUBLIC
# ${SDL2_LIBRARIES} ${SDL2_IMAGE_LIBRARIES})
# target_include_directories(lvgl_benchmark_neon PUBLIC lvgl)
# add_executable(benchmark_neon src/benchmark.c)
# target_link_libraries(benchmark_neon lvgl_benchmark_neon)
# target_compile_definitions( benchmark_neon PRIVATE
# LV_CONF_PATH="${CMAKE_CURRENT_SOURCE_DIR}/lv_conf_benchmark_neon.h" )
