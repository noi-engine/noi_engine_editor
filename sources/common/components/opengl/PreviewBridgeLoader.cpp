#include "PreviewBridgeLoader.hpp"

#include <QDebug>

namespace noi_engine_editor
{
    auto PreviewBridgeLoader::load(const QString& bridgeLibraryPath, const QString& engineLibraryPath) -> bool
    {
        if (m_library.isLoaded())
        {
            return true;
        }

        if (bridgeLibraryPath.isEmpty() || engineLibraryPath.isEmpty())
        {
            return false;
        }

        // Never unloaded: the game's scripts library, loaded later, links against this same
        // engine instance.
        m_engineLibrary.setFileName(engineLibraryPath);
        if (!m_engineLibrary.isLoaded() && !m_engineLibrary.load())
        {
            qWarning() << "[PreviewBridgeLoader] Failed to load the project's noi_engine library" << engineLibraryPath
                << ":" << m_engineLibrary.errorString();
            return false;
        }

        m_library.setFileName(bridgeLibraryPath);

        if (!m_library.load())
        {
            qWarning() << "[PreviewBridgeLoader] Failed to load preview bridge" << bridgeLibraryPath << ":" <<
                m_library.errorString();
            return false;
        }

        const auto apiVersion = reinterpret_cast<api_version_fn>(m_library.resolve("noi_engine_editor_bridge_api_version"));
        if (!apiVersion || apiVersion() != NOI_ENGINE_EDITOR_BRIDGE_API_VERSION)
        {
            qWarning() << "[PreviewBridgeLoader] Editor bridge" << bridgeLibraryPath << "uses API version"
                << (apiVersion ? apiVersion() : 0) << "but this editor needs" << NOI_ENGINE_EDITOR_BRIDGE_API_VERSION;
            m_library.unload();
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
        // Optional - added after the first bridges shipped. Intentionally left out of the
        // "missing required entry points" check below so older, already-built bridges (which
        // simply won't have it) keep loading; setGridVisible() below is a silent no-op for them.
        m_setGridVisible = reinterpret_cast<set_grid_visible_fn>(
            m_library.resolve("noi_engine_editor_bridge_set_grid_visible"));
        m_saveScene = reinterpret_cast<save_scene_fn>(
            m_library.resolve("noi_engine_editor_bridge_save_scene"));
        // Optional, same rationale as setGridVisible/saveScene above.
        m_createEntity = reinterpret_cast<create_entity_fn>(
            m_library.resolve("noi_engine_editor_bridge_create_entity"));
        m_destroyEntity = reinterpret_cast<destroy_entity_fn>(
            m_library.resolve("noi_engine_editor_bridge_destroy_entity"));
        m_duplicateEntity = reinterpret_cast<duplicate_entity_fn>(
            m_library.resolve("noi_engine_editor_bridge_duplicate_entity"));
        m_removeComponent = reinterpret_cast<remove_component_fn>(
            m_library.resolve("noi_engine_editor_bridge_remove_component"));
        m_removeComponentProperty = reinterpret_cast<remove_component_property_fn>(
            m_library.resolve("noi_engine_editor_bridge_remove_component_property"));
        m_removeMaterialProperty = reinterpret_cast<remove_material_property_fn>(
            m_library.resolve("noi_engine_editor_bridge_remove_material_property"));

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

    auto PreviewBridgeLoader::setGridVisible(const noi_engine_editor_bridge_game_handle handle,
                                              const bool visible) const -> void
    {
        if (m_setGridVisible)
        {
            m_setGridVisible(handle, visible ? 1 : 0);
        }
    }

    auto PreviewBridgeLoader::saveScene(const noi_engine_editor_bridge_game_handle handle,
                                         const QString& targetPath) const -> bool
    {
        if (!m_saveScene)
        {
            return false;
        }

        return m_saveScene(handle, targetPath.toUtf8().constData()) != 0;
    }

    auto PreviewBridgeLoader::createEntity(const noi_engine_editor_bridge_game_handle handle,
                                            const QString& name) const -> noi_engine_editor_bridge_entity_ref
    {
        if (!m_createEntity)
        {
            return {0, 0};
        }

        return m_createEntity(handle, name.toUtf8().constData());
    }

    auto PreviewBridgeLoader::destroyEntity(const noi_engine_editor_bridge_game_handle handle,
                                             const uint32_t entityId, const uint32_t entityGeneration) const -> bool
    {
        if (!m_destroyEntity)
        {
            return false;
        }

        return m_destroyEntity(handle, entityId, entityGeneration) != 0;
    }

    auto PreviewBridgeLoader::duplicateEntity(const noi_engine_editor_bridge_game_handle handle,
                                               const uint32_t entityId, const uint32_t entityGeneration,
                                               const QString& newName) const -> noi_engine_editor_bridge_entity_ref
    {
        if (!m_duplicateEntity)
        {
            return {0, 0};
        }

        return m_duplicateEntity(handle, entityId, entityGeneration, newName.toUtf8().constData());
    }

    auto PreviewBridgeLoader::removeComponent(const noi_engine_editor_bridge_game_handle handle,
                                               const uint32_t entityId, const uint32_t entityGeneration,
                                               const char* const componentType) const -> bool
    {
        if (!m_removeComponent)
        {
            return false;
        }

        return m_removeComponent(handle, entityId, entityGeneration, componentType) != 0;
    }

    auto PreviewBridgeLoader::removeComponentProperty(const noi_engine_editor_bridge_game_handle handle,
                                                        const uint32_t entityId, const uint32_t entityGeneration,
                                                        const char* const componentType,
                                                        const char* const propertyName) const -> bool
    {
        if (!m_removeComponentProperty)
        {
            return false;
        }

        return m_removeComponentProperty(handle, entityId, entityGeneration, componentType, propertyName) != 0;
    }

    auto PreviewBridgeLoader::removeMaterialProperty(const noi_engine_editor_bridge_game_handle handle,
                                                       const uint32_t materialId, const uint32_t materialGeneration,
                                                       const char* const propertyName) const -> bool
    {
        if (!m_removeMaterialProperty)
        {
            return false;
        }

        return m_removeMaterialProperty(handle, materialId, materialGeneration, propertyName) != 0;
    }
}
