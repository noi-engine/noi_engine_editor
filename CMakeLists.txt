cmake_minimum_required(VERSION 3.18)

project(noi_engine_editor VERSION 0.0.1 DESCRIPTION "noi_engine_editor" LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(NOI_ENGINE_EDITOR_NAME noi_engine_editor)
set(NOI_ENGINE_EDITOR_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(NOI_ENGINE_EDITOR_IS_MAIN_PROJECT OFF)
if (CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    set(NOI_ENGINE_EDITOR_IS_MAIN_PROJECT ON)
endif ()

set(NOI_ENGINE_EDITOR_VERSION ${PROJECT_VERSION})
set(NOI_ENGINE_EDITOR_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})

if (NOI_ENGINE_EDITOR_IS_MAIN_PROJECT)
    configure_file(
            ${NOI_ENGINE_EDITOR_SOURCE_DIR}/.templates/${NOI_ENGINE_EDITOR_NAME}Config.hpp.in
            ${NOI_ENGINE_EDITOR_SOURCE_DIR}/sources/${NOI_ENGINE_EDITOR_NAME}Config.hpp @ONLY)
endif ()

add_subdirectory(external/Templi)
add_subdirectory(external/noi_engine)

# QT
set(CMAKE_AUTORCC ON)
set(NOI_ENGINE_EDITOR_PROJECT_NAME noi_engine_editor)
set(QML_IMPORT_PATH "${CMAKE_BINARY_DIR}" CACHE STRING "QML Import Path" FORCE)

find_package(Qt6 REQUIRED COMPONENTS Quick OpenGL)

qt_standard_project_setup(REQUIRES 6.10)
qt_add_executable(${NOI_ENGINE_EDITOR_PROJECT_NAME} resources.qrc main.cpp)

set(NOI_ENGINE_EDITOR_QML_SINGLETONS
        sources/Router.qml
        sources/common/components/Theme.qml
        sources/common/components/icons/IconLoader.qml
        sources/common/components/fonts/CustomFont.qml
)

set_source_files_properties(${NOI_ENGINE_EDITOR_QML_SINGLETONS} PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(${NOI_ENGINE_EDITOR_PROJECT_NAME}
        URI noi_engine_editor
        VERSION 0.0.1

        # Common
        QML_FILES
        Main.qml
        sources/common/components/AppButton.qml
        sources/common/components/IconBadge.qml
        sources/common/components/CustomPage.qml
        sources/common/components/SearchField.qml
        sources/common/components/icons/MuiIcon.qml
        sources/common/components/icons/IconLoaderCreator.js
        sources/common/components/icons/MaterialSymbolsRegular/codepoints.js
        ${NOI_ENGINE_EDITOR_QML_SINGLETONS}
        SOURCES
        sources/noi_engine_editorConfig.hpp
        sources/common/utils/JsonSerializer.hpp
        sources/common/utils/PathResolver.cpp
        sources/common/utils/PathResolver.hpp
        sources/common/utils/JsonIO.cpp
        sources/common/utils/JsonIO.hpp

        # Pages
        QML_FILES
        sources/pages/HomePage.qml
        sources/pages/CreateProjectPage.qml
        sources/pages/ProjectEditorPage.qml

        # home
        QML_FILES
        sources/features/home/components/ActionCard.qml
        sources/features/home/components/EmptyState.qml
        sources/features/home/components/HeroHeader.qml
        sources/features/home/components/QuickActionsRow.qml

        # projects
        QML_FILES
        sources/features/projects/components/RecentProjectItem.qml
        sources/features/projects/components/RecentProjectsSection.qml
        SOURCES
        sources/features/projects/ProjectInfo.hpp
        sources/features/projects/ProjectInfo.cpp
        sources/features/projects/ProjectCreator.hpp
        sources/features/projects/ProjectCreator.cpp
        sources/features/projects/RecentProjectsManager.hpp
        sources/features/projects/RecentProjectsManager.cpp
        sources/features/projects/CurrentProjectManager.hpp
        sources/features/projects/CurrentProjectManager.cpp
        sources/features/projects/components/RecentProjectsModel.hpp
        sources/features/projects/components/RecentProjectsModel.cpp

        # settings
        SOURCES
        sources/features/settings/SettingsManager.hpp
        sources/features/settings/SettingsManager.cpp
)

set_target_properties(${NOI_ENGINE_EDITOR_PROJECT_NAME} PROPERTIES
        #    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appnoi_engine_editor
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
        MACOSX_BUNDLE TRUE
        WIN32_EXECUTABLE TRUE
)

# TODO(begin): find a better way
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
)
# TODO(end): find a better way

target_link_directories(${NOI_ENGINE_EDITOR_PROJECT_NAME}
        PRIVATE
        ${CMAKE_BINARY_DIR}/lib
)

target_link_libraries(${NOI_ENGINE_EDITOR_PROJECT_NAME}
        PRIVATE
        Qt6::Quick
        Qt6::OpenGL
        Templi
        noi_engine
)

set_target_properties(${NOI_ENGINE_EDITOR_PROJECT_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
