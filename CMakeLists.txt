cmake_minimum_required(VERSION 3.18)

project(noi_engine_editor VERSION 0.0.1 DESCRIPTION "noi_engine_editor" LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# QT
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(NOI_ENGINE_EDITOR_PROJECT_NAME noi_engine_editor)
set(QML_IMPORT_PATH "${CMAKE_BINARY_DIR}" CACHE STRING "QML Import Path" FORCE)

find_package(Qt6 REQUIRED COMPONENTS Core Quick OpenGL)

qt_standard_project_setup(REQUIRES 6.10)

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

add_subdirectory(external/zip EXCLUDE_FROM_ALL)
add_subdirectory(external/Templi)

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

qt_add_qml_module(${NOI_ENGINE_EDITOR_PROJECT_NAME}
        URI noi_engine_editor
        VERSION 0.0.1

        # Common
        QML_FILES
        Main.qml
        sources/common/components/AppButton.qml
        sources/common/components/CustomPage.qml
        sources/common/components/IconBadge.qml
        sources/common/components/SearchField.qml
        sources/common/components/PanelSearchField.qml
        sources/common/components/icons/IconLoaderCreator.js
        sources/common/components/icons/MaterialSymbolsRegular/codepoints.js
        sources/common/components/icons/MuiIcon.qml
        sources/common/utils/LocalPathAndUrlConverter.js
        ${NOI_ENGINE_EDITOR_QML_SINGLETONS}
        SOURCES
        sources/common/components/opengl/PreviewBridgeLoader.hpp
        sources/common/components/opengl/PreviewBridgeLoader.cpp
        sources/common/components/opengl/OpenglRenderer.hpp
        sources/common/components/opengl/OpenglRenderer.cpp
        sources/common/components/opengl/OpenglView.hpp
        sources/common/components/opengl/OpenglView.cpp
        sources/common/utils/JsonIO.hpp
        sources/common/utils/JsonIO.cpp
        sources/common/utils/EditorBridgeResolver.hpp
        sources/common/utils/EditorBridgeResolver.cpp
        sources/common/utils/JsonSerializer.hpp
        sources/common/utils/PathResolver.hpp
        sources/common/utils/PathResolver.cpp
        sources/common/utils/ZipExtractor.hpp
        sources/common/utils/ZipExtractor.cpp
        sources/common/utils/ZipInstall.hpp
        sources/common/utils/ZipInstall.cpp
        sources/noi_engine_editorConfig.hpp

        # Pages
        QML_FILES
        sources/pages/HomePage.qml
        sources/pages/ProjectEditorPage.qml

        # home
        QML_FILES
        sources/features/home/components/ActionCard.qml
        sources/features/home/components/EmptyState.qml
        sources/features/home/components/HeroHeader.qml
        sources/features/home/components/QuickActionsRow.qml

        # projects
        QML_FILES
        sources/features/projects/components/CreateProjectDialog.qml
        sources/features/projects/components/RecentProjectItem.qml
        sources/features/projects/components/RecentProjectsSection.qml
        sources/features/projects/components/ToolStatusRow.qml
        sources/features/projects/components/ProjectOpenErrorDialog.qml
        SOURCES
        sources/features/projects/CurrentProjectManager.hpp
        sources/features/projects/CurrentProjectManager.cpp
        sources/features/projects/ProjectCreator.hpp
        sources/features/projects/ProjectCreator.cpp
        sources/features/projects/ProjectInfo.hpp
        sources/features/projects/ProjectInfo.cpp
        sources/features/projects/RecentProjectsManager.hpp
        sources/features/projects/RecentProjectsManager.cpp
        sources/features/projects/components/RecentProjectsModel.hpp
        sources/features/projects/components/RecentProjectsModel.cpp

        # settings
        SOURCES
        sources/features/settings/SettingsManager.hpp
        sources/features/settings/SettingsManager.cpp
        QML_FILES
        sources/features/settings/components/SettingsDialog.qml

        # templates
        SOURCES
        sources/features/templates/LocalTemplateManager.hpp
        sources/features/templates/LocalTemplateManager.cpp
        sources/features/templates/TemplateInfo.hpp
        sources/features/templates/TemplateInfo.cpp
        sources/features/templates/TemplateInstaller.hpp
        sources/features/templates/TemplateInstaller.cpp
        sources/features/templates/TemplateManager.hpp
        sources/features/templates/TemplateManager.cpp
        sources/features/templates/TemplateUrlResolver.hpp
        sources/features/templates/TemplateUrlResolver.cpp
        QML_FILES
        sources/features/templates/components/TemplateMarketplaceDialog.qml

        # tools
        SOURCES
        sources/features/tools/ToolInstaller.hpp
        sources/features/tools/ToolInstaller.cpp
        sources/features/tools/ToolsManager.hpp
        sources/features/tools/ToolsManager.cpp
        sources/features/tools/ToolUrlResolver.hpp
        sources/features/tools/ToolUrlResolver.cpp
        QML_FILES
        sources/features/tools/components/ToolsSettingsTab.qml

        # editor
        QML_FILES
        sources/features/editor/components/AddScriptDialog.qml
        sources/features/editor/components/AddSpriteDialog.qml
        sources/features/editor/components/BottomTabButton.qml
        sources/features/editor/components/CompilerOutputPanel.qml
        sources/features/editor/components/EditorLogsPanel.qml
        sources/features/editor/components/EditorToolbar.qml
        sources/features/editor/components/hierarchy/HierarchyItem.qml
        sources/features/editor/components/hierarchy/FolderItem.qml
        sources/features/editor/components/hierarchy/MoveToFolderDialog.qml
        sources/features/editor/components/hierarchy/EntityPresetMenu.qml
        sources/features/editor/components/ImportTextureDialog.qml
        sources/features/editor/components/InspectorPanel.qml
        sources/features/editor/components/UnsavedChangesDialog.qml
        sources/features/editor/components/inspector/ComponentSection.qml
        sources/features/editor/components/inspector/PropertyRow.qml
        sources/features/editor/components/inspector/AddPropertyPopup.qml
        sources/features/editor/components/inspector/SpriteSection.qml
        sources/features/editor/components/inspector/ScriptsSection.qml
        sources/features/editor/components/inspector/MaterialChangeDialog.qml
        sources/features/editor/components/search/GlobalSearchPopup.qml
        sources/features/editor/components/LogPanel.qml
        sources/features/editor/components/LoadedResourceItem.qml
        sources/features/editor/components/LoadedResourcesPanel.qml
        sources/features/editor/components/ProjectSettingsDialog.qml
        sources/features/editor/components/PropertyField.qml
        sources/features/editor/components/SceneHierarchyPanel.qml
        sources/features/editor/components/resources/DeleteConfirmDialog.qml
        sources/features/editor/components/resources/ImportDialog.qml
        sources/features/editor/components/resources/NewFolderDialog.qml
        sources/features/editor/components/resources/RenameDialog.qml
        sources/features/editor/components/resources/ResourceDropArea.qml
        sources/features/editor/components/resources/ResourceItemDelegate.qml
        sources/features/editor/components/resources/ResourcePanel.qml
        sources/features/editor/components/resources/ResourceToolbar.qml
        sources/features/editor/components/scenes/SceneBrowserPanel.qml
        sources/features/editor/components/scenes/NewSceneDialog.qml
        sources/features/editor/components/viewport/ToolButtonCustom.qml
        sources/features/editor/components/viewport/ViewportPanel.qml
        sources/features/editor/components/viewport/ViewportToolbar.qml
        sources/features/editor/components/viewport/CameraFrameHandles.qml
        sources/features/editor/components/viewport/EntityPicking.qml
        sources/features/editor/components/viewport/ViewportViewState.qml
        sources/features/editor/components/viewport/ViewportNavigation.qml
        SOURCES
        sources/features/editor/CurrentProjectResourcesManager.hpp
        sources/features/editor/CurrentProjectResourcesManager.cpp
        sources/features/editor/EditorLogger.hpp
        sources/features/editor/EditorLogger.cpp
        sources/features/editor/ProjectBuilder.hpp
        sources/features/editor/ProjectBuilder.cpp
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
