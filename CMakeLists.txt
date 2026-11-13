cmake_minimum_required(VERSION 3.16)

project(kikoe
        VERSION 0.1.0
        DESCRIPTION "Free, unlimited, offline audio/video transcription powered by whisper.cpp"
        HOMEPAGE_URL "https://github.com/nekonaru/Kikoe"
        LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release)
endif()

option(KIKOE_BUILD_CLI "Build the kikoe command line tool" ON)
option(KIKOE_BUILD_TESTS "Build the unit tests" ON)
option(KIKOE_USE_GPU "Build whisper.cpp with GPU acceleration (CPU is the default and tested path)" OFF)

include(GNUInstallDirs)

# whisper.cpp lives in third_party/whisper.cpp as a git submodule.
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/whisper.cpp/CMakeLists.txt")
    message(FATAL_ERROR
        "whisper.cpp submodule is missing. Run: git submodule update --init --recursive")
endif()

set(WHISPER_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_BENCHMARKS OFF CACHE BOOL "" FORCE)
set(WHISPER_ALL_WARNINGS OFF CACHE BOOL "" FORCE)

if(KIKOE_USE_GPU)
    if(APPLE)
        set(GGML_METAL ON CACHE BOOL "" FORCE)
    else()
        set(GGML_VULKAN ON CACHE BOOL "" FORCE)
    endif()
endif()

add_subdirectory(third_party/whisper.cpp)

add_library(kikoe-core STATIC
    core/src/kikoe.cpp)
target_include_directories(kikoe-core
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/core/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
target_link_libraries(kikoe-core PUBLIC whisper)

if(KIKOE_BUILD_CLI)
    add_executable(kikoe cli/main.cpp)
    target_link_libraries(kikoe PRIVATE kikoe-core)
endif()

if(KIKOE_BUILD_TESTS)
    enable_testing()
    add_executable(kikoe-test-core tests/test_core.cpp)
    target_link_libraries(kikoe-test-core PRIVATE kikoe-core)
    add_test(NAME core COMMAND kikoe-test-core)
endif()

install(TARGETS kikoe-core
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES core/include/kikoe.h
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
if(KIKOE_BUILD_CLI)
    install(TARGETS kikoe RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()
