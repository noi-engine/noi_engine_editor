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
        m_enumerateResources = reinterpret_cast<enumerate_resources_fn>(
            m_library.resolve("noi_engine_editor_bridge_enumerate_resources"));
        m_enumerateEntities = reinterpret_cast<enumerate_entities_fn>(
            m_library.resolve("noi_engine_editor_bridge_enumerate_entities"));
        m_enumerateComponentProperties = reinterpret_cast<enumerate_component_properties_fn>(
            m_library.resolve("noi_engine_editor_bridge_enumerate_component_properties"));
        m_setComponentProperty = reinterpret_cast<set_component_property_fn>(
            m_library.resolve("noi_engine_editor_bridge_set_component_property"));
        m_addComponent = reinterpret_cast<add_component_fn>(
            m_library.resolve("noi_engine_editor_bridge_add_component"));
        m_enumerateMaterialProperties = reinterpret_cast<enumerate_material_properties_fn>(
            m_library.resolve("noi_engine_editor_bridge_enumerate_material_properties"));
        m_setMaterialProperty = reinterpret_cast<set_material_property_fn>(
            m_library.resolve("noi_engine_editor_bridge_set_material_property"));
        m_setKeyPressed = reinterpret_cast<set_key_pressed_fn>(
            m_library.resolve("noi_engine_editor_bridge_set_key_pressed"));
        m_setKeyReleased = reinterpret_cast<set_key_released_fn>(
            m_library.resolve("noi_engine_editor_bridge_set_key_released"));
        m_releaseAllKeys = reinterpret_cast<release_all_keys_fn>(
            m_library.resolve("noi_engine_editor_bridge_release_all_keys"));
        m_resetTimer = reinterpret_cast<reset_timer_fn>(
            m_library.resolve("noi_engine_editor_bridge_reset_timer"));

        if (!m_initGl || !m_create || !m_destroy || !m_run || !m_onResize || !m_setScene2d || !m_loadScripts ||
            !m_engineVersion || !m_enumerateResources || !m_enumerateEntities || !m_enumerateComponentProperties ||
            !m_setComponentProperty || !m_addComponent || !m_enumerateMaterialProperties || !m_setMaterialProperty ||
            !m_setKeyPressed || !m_setKeyReleased || !m_releaseAllKeys || !m_resetTimer)
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

    auto PreviewBridgeLoader::enumerateResources(const noi_engine_editor_bridge_game_handle handle,
                                                  const noi_engine_editor_bridge_resource_entry_callback callback,
                                                  void* const userData) const -> void
    {
        m_enumerateResources(handle, callback, userData);
    }

    auto PreviewBridgeLoader::enumerateEntities(const noi_engine_editor_bridge_game_handle handle,
                                                 const noi_engine_editor_bridge_entity_entry_callback callback,
                                                 void* const userData) const -> void
    {
        m_enumerateEntities(handle, callback, userData);
    }

    auto PreviewBridgeLoader::enumerateComponentProperties(
        const noi_engine_editor_bridge_game_handle handle, const uint32_t entityId, const uint32_t entityGeneration,
        const char* const componentType, const noi_engine_editor_bridge_property_entry_callback callback,
        void* const userData) const -> void
    {
        m_enumerateComponentProperties(handle, entityId, entityGeneration, componentType, callback, userData);
    }

    auto PreviewBridgeLoader::setComponentProperty(const noi_engine_editor_bridge_game_handle handle,
                                                    const uint32_t entityId, const uint32_t entityGeneration,
                                                    const char* const componentType, const char* const propertyName,
                                                    const noi_engine_editor_bridge_property_value value) const -> bool
    {
        return m_setComponentProperty(handle, entityId, entityGeneration, componentType, propertyName, value) != 0;
    }

    auto PreviewBridgeLoader::addComponent(const noi_engine_editor_bridge_game_handle handle, const uint32_t entityId,
                                            const uint32_t entityGeneration,
                                            const char* const componentType) const -> bool
    {
        return m_addComponent(handle, entityId, entityGeneration, componentType) != 0;
    }

    auto PreviewBridgeLoader::enumerateMaterialProperties(
        const noi_engine_editor_bridge_game_handle handle, const uint32_t materialId, const uint32_t materialGeneration,
        const noi_engine_editor_bridge_property_entry_callback callback, void* const userData) const -> void
    {
        m_enumerateMaterialProperties(handle, materialId, materialGeneration, callback, userData);
    }

    auto PreviewBridgeLoader::setMaterialProperty(const noi_engine_editor_bridge_game_handle handle,
                                                   const uint32_t materialId, const uint32_t materialGeneration,
                                                   const char* const propertyName,
                                                   const noi_engine_editor_bridge_property_value value) const -> bool
    {
        return m_setMaterialProperty(handle, materialId, materialGeneration, propertyName, value) != 0;
    }

    auto PreviewBridgeLoader::setKeyPressed(const noi_engine_editor_bridge_game_handle handle,
                                             const int keyCode) const -> void
    {
        m_setKeyPressed(handle, keyCode);
    }

    auto PreviewBridgeLoader::setKeyReleased(const noi_engine_editor_bridge_game_handle handle,
                                              const int keyCode) const -> void
    {
        m_setKeyReleased(handle, keyCode);
    }

    auto PreviewBridgeLoader::releaseAllKeys(const noi_engine_editor_bridge_game_handle handle) const -> void
    {
        m_releaseAllKeys(handle);
    }

    auto PreviewBridgeLoader::resetTimer(const noi_engine_editor_bridge_game_handle handle) const -> void
    {
        m_resetTimer(handle);
    }
}
