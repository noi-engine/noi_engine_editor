#pragma once

#include <QLibrary>
#include <QString>
#include <noi_engine_editor_bridge/bridge_api.h>

namespace noi_engine_editor
{
    class PreviewBridgeLoader
    {
    public:
        [[nodiscard]] auto load(const QString& bridgeLibraryPath) -> bool;
        [[nodiscard]] auto isLoaded() const -> bool;
        [[nodiscard]] auto engineVersion() const -> QString;

        auto initGl(noi_engine_editor_bridge_gl_proc_loader loader) const -> void;
        [[nodiscard]] auto create(int gameWidth, int gameHeight,
                                   const QString& resourcesPath) const -> noi_engine_editor_bridge_game_handle;
        auto destroy(noi_engine_editor_bridge_game_handle handle) const -> void;
        auto run(noi_engine_editor_bridge_game_handle handle) const -> void;
        auto onResize(noi_engine_editor_bridge_game_handle handle, int width, int height) const -> void;
        auto setScene2d(noi_engine_editor_bridge_game_handle handle, const QString& scenePath) const -> void;
        [[nodiscard]] auto loadScripts(noi_engine_editor_bridge_game_handle handle,
                                        const QString& scriptsLibraryPath) const -> bool;

    private:
        using init_gl_fn = void (*)(noi_engine_editor_bridge_gl_proc_loader);
        using create_fn = noi_engine_editor_bridge_game_handle (*)(int, int, const char*);
        using destroy_fn = void (*)(noi_engine_editor_bridge_game_handle);
        using run_fn = void (*)(noi_engine_editor_bridge_game_handle);
        using on_resize_fn = void (*)(noi_engine_editor_bridge_game_handle, int, int);
        using set_scene_2d_fn = void (*)(noi_engine_editor_bridge_game_handle, const char*);
        using load_scripts_fn = int (*)(noi_engine_editor_bridge_game_handle, const char*);
        using engine_version_fn = const char* (*)();

        QLibrary m_library;
        init_gl_fn m_initGl{nullptr};
        create_fn m_create{nullptr};
        destroy_fn m_destroy{nullptr};
        run_fn m_run{nullptr};
        on_resize_fn m_onResize{nullptr};
        set_scene_2d_fn m_setScene2d{nullptr};
        load_scripts_fn m_loadScripts{nullptr};
        engine_version_fn m_engineVersion{nullptr};
    };
}
