cmake_minimum_required(VERSION 3.18)

project(noi_engine_editor VERSION 0.0.2 DESCRIPTION "noi_engine_editor" LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# QT
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(NOI_ENGINE_EDITOR_PROJECT_NAME noi_engine_editor)
set(QML_IMPORT_PATH "${CMAKE_BINARY_DIR}" CACHE STRING "QML Import Path" FORCE)

find_package(Qt6 REQUIRED COMPONENTS Core Quick OpenGL)

qt_standard_project_setup(REQUIRES 6.12)

set(NOI_ENGINE_EDITOR_NAME noi_engine_editor)
set(NOI_ENGINE_EDITOR_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(NOI_ENGINE_EDITOR_IS_MAIN_PROJECT OFF)
if (CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    set(NOI_ENGINE_EDITOR_IS_MAIN_PROJECT ON)
endif ()

set(NOI_ENGINE_EDITOR_VERSION ${PROJECT_VERSION})
set(NOI_ENGINE_EDITOR_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})

# Generated header (version...), kept out of the source tree.
configure_file(
        ${NOI_ENGINE_EDITOR_SOURCE_DIR}/.templates/${NOI_ENGINE_EDITOR_NAME}Config.hpp.in
        ${CMAKE_CURRENT_BINARY_DIR}/${NOI_ENGINE_EDITOR_NAME}Config.hpp @ONLY)

add_subdirectory(external/zip EXCLUDE_FROM_ALL)
add_subdirectory(external/Templi)
# Templi's parser.cpp uses std::stringstream without including <sstream>, which libc++ (macOS)
# rejects. Remove once the Templi submodule includes it.
if (NOT MSVC)
    target_compile_options(Templi PRIVATE -include sstream)
endif ()

qt_add_executable(${NOI_ENGINE_EDITOR_PROJECT_NAME} resources.qrc main.cpp)

set(NOI_ENGINE_EDITOR_QML_SINGLETONS
        sources/Router.qml
        sources/common/components/Theme.qml
        sources/common/components/icons/IconLoader.qml
        sources/common/components/fonts/CustomFont.qml
)

set_source_files_properties(${NOI_ENGINE_EDITOR_QML_SINGLETONS} PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

# qmlcachegen (Qt 6.10) crashes in QQmlJSLookupSignaturesRecorder::cantDesync on this file:
# load it as plain QML instead of ahead-of-time compiling it.
set_source_files_properties(sources/features/editor/components/viewport/ViewportPanel.qml
        PROPERTIES QT_QML_SKIP_CACHEGEN TRUE)

# Sources are collected by folder, so a new file only has to be dropped in the right place
# (re-run CMake to pick it up; CONFIGURE_DEPENDS makes ninja re-run CMake forever with qt_add_qml_module):
#   sources/common/       shared QML components and helpers (no feature knowledge)
#   sources/features/<f>/ one folder per feature: C++ managers at its root, QML in components/
#   sources/pages/        top-level pages, assembled from the features
file(GLOB_RECURSE NOI_ENGINE_EDITOR_QML_FILES
        RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
        Main.qml sources/*.qml sources/*.js)
file(GLOB_RECURSE NOI_ENGINE_EDITOR_CPP_FILES
        RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
        sources/*.hpp sources/*.cpp)

qt_add_qml_module(${NOI_ENGINE_EDITOR_PROJECT_NAME}
        URI noi_engine_editor
        VERSION 0.0.1
        QML_FILES ${NOI_ENGINE_EDITOR_QML_FILES}
        SOURCES ${NOI_ENGINE_EDITOR_CPP_FILES}
)

set_target_properties(${NOI_ENGINE_EDITOR_PROJECT_NAME} PROPERTIES
        #    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appnoi_engine_editor
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
        MACOSX_BUNDLE TRUE
        WIN32_EXECUTABLE TRUE
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

file(GLOB_RECURSE ALL_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/sources/*.hpp")

set(INCLUDE_DIRS "")
foreach(HEADER_FILE ${ALL_HEADERS})
    get_filename_component(HEADER_DIR ${HEADER_FILE} DIRECTORY)
    list(APPEND INCLUDE_DIRS ${HEADER_DIR})
endforeach()
list(REMOVE_DUPLICATES INCLUDE_DIRS)

target_include_directories(${NOI_ENGINE_EDITOR_PROJECT_NAME}
        PRIVATE
        ${CMAKE_CURRENT_BINARY_DIR}
        ${INCLUDE_DIRS}
        ${CMAKE_CURRENT_SOURCE_DIR}/bridge/include
)

target_link_libraries(${NOI_ENGINE_EDITOR_PROJECT_NAME}
        PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::OpenGL
        Templi
        zip
)
