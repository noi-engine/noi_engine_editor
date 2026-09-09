#include "PreviewBridgeLoader.hpp"

#include <QDebug>

namespace noi_engine_editor
{
    auto PreviewBridgeLoader::load(const QString& bridgeLibraryPath) -> bool
    {
        if (m_library.isLoaded())
        {
            return true;
        }

        m_library.setFileName(bridgeLibraryPath);

        if (!m_library.load())
        {
            qWarning() << "[PreviewBridgeLoader] Failed to load preview bridge" << bridgeLibraryPath << ":" <<
                m_library.errorString();
            return false;
        }

        m_initGl = reinterpret_cast<init_gl_fn>(m_library.resolve("noi_engine_editor_bridge_init_gl"));
        m_create = reinterpret_cast<create_fn>(m_library.resolve("noi_engine_editor_bridge_create"));
        m_destroy = reinterpret_cast<destroy_fn>(m_library.resolve("noi_engine_editor_bridge_destroy"));
        m_run = reinterpret_cast<run_fn>(m_library.resolve("noi_engine_editor_bridge_run"));
        m_onResize = reinterpret_cast<on_resize_fn>(m_library.resolve("noi_engine_editor_bridge_on_resize"));
        m_setScene2d = reinterpret_cast<set_scene_2d_fn>(m_library.resolve("noi_engine_editor_bridge_set_scene_2d"));
        m_loadScripts = reinterpret_cast<load_scripts_fn>(m_library.resolve("noi_engine_editor_bridge_load_scripts"));
        m_engineVersion = reinterpret_cast<engine_version_fn>(m_library.resolve("noi_engine_editor_bridge_engine_version"));

        if (!m_initGl || !m_create || !m_destroy || !m_run || !m_onResize || !m_setScene2d || !m_loadScripts ||
            !m_engineVersion)
        {
            qWarning() << "[PreviewBridgeLoader] Preview bridge" << bridgeLibraryPath <<
                "is missing one or more required entry points";
            m_library.unload();
            return false;
        }

        return true;
    }

    auto PreviewBridgeLoader::isLoaded() const -> bool
    {
        return m_library.isLoaded();
    }

    auto PreviewBridgeLoader::engineVersion() const -> QString
    {
        return m_engineVersion ? QString::fromUtf8(m_engineVersion()) : QString{};
    }

    auto PreviewBridgeLoader::initGl(const noi_engine_editor_bridge_gl_proc_loader loader) const -> void
    {
        m_initGl(loader);
    }

    auto PreviewBridgeLoader::create(const int gameWidth, const int gameHeight,
                                      const QString& resourcesPath) const -> noi_engine_editor_bridge_game_handle
    {
        return m_create(gameWidth, gameHeight, resourcesPath.toUtf8().constData());
    }

    auto PreviewBridgeLoader::destroy(const noi_engine_editor_bridge_game_handle handle) const -> void
    {
        m_destroy(handle);
    }

    auto PreviewBridgeLoader::run(const noi_engine_editor_bridge_game_handle handle) const -> void
    {
        m_run(handle);
    }

    auto PreviewBridgeLoader::onResize(const noi_engine_editor_bridge_game_handle handle, const int width,
                                        const int height) const -> void
    {
        m_onResize(handle, width, height);
    }

    auto PreviewBridgeLoader::setScene2d(const noi_engine_editor_bridge_game_handle handle,
                                          const QString& scenePath) const -> void
    {
        m_setScene2d(handle, scenePath.toUtf8().constData());
    }

    auto PreviewBridgeLoader::loadScripts(const noi_engine_editor_bridge_game_handle handle,
                                           const QString& scriptsLibraryPath) const -> bool
    {
        return m_loadScripts(handle, scriptsLibraryPath.toUtf8().constData()) != 0;
    }
}
