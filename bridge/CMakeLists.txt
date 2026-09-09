cmake_minimum_required(VERSION 3.23)

project(noi_engine_editor_bridge VERSION 0.0.1 DESCRIPTION "noi_engine_editor preview bridge" LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if (NOT DEFINED NOI_ENGINE_SOURCE_DIR)
    set(NOI_ENGINE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/external/noi_engine)
endif ()

add_subdirectory(${NOI_ENGINE_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR}/noi_engine)

add_library(noi_engine_editor_bridge SHARED
        src/bridge.cpp
)

target_include_directories(noi_engine_editor_bridge PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(noi_engine_editor_bridge PRIVATE
        noi_engine::noi_engine
        ${CMAKE_DL_LIBS}
)

set_target_properties(noi_engine_editor_bridge PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/libs"
        SUFFIX ".so"
)

install(TARGETS noi_engine_editor_bridge
        LIBRARY DESTINATION .
        RUNTIME DESTINATION .
)
