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
option(KIKOE_BUILD_FFI "Build kikoe-ffi, the shared library for Dart FFI (desktop and mobile)" ON)
option(KIKOE_USE_GPU "Build whisper.cpp with GPU acceleration (CPU is the default and tested path)" OFF)
option(KIKOE_USE_CUDA "Build whisper.cpp with CUDA acceleration" OFF)

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

# Static whisper/ggml so the CLI is a single binary and tests need no PATH setup.
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)

# ggml runs its own thread pool; OpenMP would add a runtime DLL dependency
# that minimal installers and Android builds cannot rely on.
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)

if(KIKOE_USE_CUDA)
    set(GGML_CUDA ON CACHE BOOL "" FORCE)
elseif(KIKOE_USE_GPU)
    if(APPLE)
        set(GGML_METAL ON CACHE BOOL "" FORCE)
    else()
        set(GGML_VULKAN ON CACHE BOOL "" FORCE)
    endif()
endif()

add_subdirectory(third_party/whisper.cpp)

set(KIKOE_CORE_SOURCES
    core/src/kikoe.cpp
    core/src/error.cpp
    core/src/audio/wav_reader.cpp
    core/src/audio/media_decoder.cpp
    core/src/audio/media_pcm.cpp
    core/src/engine/engine.cpp
    core/src/format/formatter.cpp
    core/src/util/sha256.cpp
    core/src/model/model_registry.cpp
    core/src/model/model_manager.cpp)

add_library(kikoe-core STATIC
    ${KIKOE_CORE_SOURCES})
target_include_directories(kikoe-core
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/core/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/third_party/whisper.cpp/include)
target_link_libraries(kikoe-core PUBLIC whisper)

if(KIKOE_BUILD_CLI)
    add_executable(kikoe cli/main.cpp)
    target_link_libraries(kikoe PRIVATE kikoe-core)
endif()

if(KIKOE_BUILD_FFI)
    add_library(kikoe-ffi SHARED
        ${KIKOE_CORE_SOURCES})
    target_include_directories(kikoe-ffi
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/core/include>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
        PRIVATE
            ${CMAKE_CURRENT_SOURCE_DIR}/third_party/whisper.cpp/include)
    target_compile_definitions(kikoe-ffi PRIVATE KIKOE_BUILD_SHARED)
    target_link_libraries(kikoe-ffi PRIVATE whisper)
    set_target_properties(kikoe-ffi PROPERTIES OUTPUT_NAME kikoe_ffi)
endif()

if(KIKOE_BUILD_TESTS)
    enable_testing()
    add_executable(kikoe-test-core tests/test_core.cpp)
    target_link_libraries(kikoe-test-core PRIVATE kikoe-core)
    add_test(NAME core COMMAND kikoe-test-core)

    add_executable(kikoe-test-formatter tests/test_formatter.cpp)
    target_link_libraries(kikoe-test-formatter PRIVATE kikoe-core)
    add_test(NAME formatter COMMAND kikoe-test-formatter)

    add_executable(kikoe-contract-c tests/contract_c.c)
    target_link_libraries(kikoe-contract-c PRIVATE kikoe-core)
    add_test(NAME contract_c COMMAND kikoe-contract-c)
endif()

install(TARGETS kikoe-core
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES core/include/kikoe.h
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
if(KIKOE_BUILD_CLI)
    install(TARGETS kikoe RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()
