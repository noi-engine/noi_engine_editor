#pragma once

#include <QLibrary>
#include <QString>
#include <noi_engine_editor_bridge/bridge_api.h>

namespace noi_engine_editor
{
    class PreviewBridgeLoader
    {
    public:
        // Loads the project's noi_engine library first, then the editor bridge (which needs it and
        // doesn't ship its own), and checks the bridge implements this editor's API version.
        [[nodiscard]] auto load(const QString& bridgeLibraryPath, const QString& engineLibraryPath) -> bool;
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
        auto enumerateResources(noi_engine_editor_bridge_game_handle handle,
                                 noi_engine_editor_bridge_resource_entry_callback callback,
                                 void* userData) const -> void;
        auto enumerateEntities(noi_engine_editor_bridge_game_handle handle,
                                noi_engine_editor_bridge_entity_entry_callback callback,
                                void* userData) const -> void;
        auto enumerateComponentProperties(noi_engine_editor_bridge_game_handle handle, uint32_t entityId,
                                           uint32_t entityGeneration, const char* componentType,
                                           noi_engine_editor_bridge_property_entry_callback callback,
                                           void* userData) const -> void;
        [[nodiscard]] auto setComponentProperty(noi_engine_editor_bridge_game_handle handle, uint32_t entityId,
                                                 uint32_t entityGeneration, const char* componentType,
                                                 const char* propertyName,
                                                 noi_engine_editor_bridge_property_value value) const -> bool;
        [[nodiscard]] auto addComponent(noi_engine_editor_bridge_game_handle handle, uint32_t entityId,
                                         uint32_t entityGeneration, const char* componentType) const -> bool;
        auto enumerateMaterialProperties(noi_engine_editor_bridge_game_handle handle, uint32_t materialId,
                                          uint32_t materialGeneration,
                                          noi_engine_editor_bridge_property_entry_callback callback,
                                          void* userData) const -> void;
        [[nodiscard]] auto setMaterialProperty(noi_engine_editor_bridge_game_handle handle, uint32_t materialId,
                                                uint32_t materialGeneration, const char* propertyName,
                                                noi_engine_editor_bridge_property_value value) const -> bool;

        auto setKeyPressed(noi_engine_editor_bridge_game_handle handle, int keyCode) const -> void;
        auto setKeyReleased(noi_engine_editor_bridge_game_handle handle, int keyCode) const -> void;
        auto releaseAllKeys(noi_engine_editor_bridge_game_handle handle) const -> void;
        auto resetTimer(noi_engine_editor_bridge_game_handle handle) const -> void;
        // Optional (bridge 0.0.3+): no-op on older bridges, which keep running the game in edit mode.
        auto setPlaying(noi_engine_editor_bridge_game_handle handle, bool playing) const -> void;

        // Optional: older bridges built before this symbol existed simply won't have it resolved
        // (see m_setGridVisible's resolve() call in the .cpp) - not part of the "missing required
        // entry points" check, so those bridges still load fine; this call just becomes a no-op.
        auto setGridVisible(noi_engine_editor_bridge_game_handle handle, bool visible) const -> void;

        // Optional, same rationale as setGridVisible(): older bridges won't have this resolved
        // and the call becomes a no-op (returns false) instead of failing to load.
        [[nodiscard]] auto saveScene(noi_engine_editor_bridge_game_handle handle,
                                      const QString& targetPath) const -> bool;

        // Optional (same rationale as saveScene/setGridVisible) - entity/component CRUD.
        // A zeroed {0, 0} ref or false/0-returning call means either failure or an unresolved
        // (older) bridge; callers can't tell those apart, same as every other optional entry
        // point here.
        [[nodiscard]] auto createEntity(noi_engine_editor_bridge_game_handle handle,
                                         const QString& name) const -> noi_engine_editor_bridge_entity_ref;
        [[nodiscard]] auto destroyEntity(noi_engine_editor_bridge_game_handle handle, uint32_t entityId,
                                          uint32_t entityGeneration) const -> bool;
        [[nodiscard]] auto duplicateEntity(noi_engine_editor_bridge_game_handle handle, uint32_t entityId,
                                            uint32_t entityGeneration,
                                            const QString& newName) const -> noi_engine_editor_bridge_entity_ref;
        [[nodiscard]] auto removeComponent(noi_engine_editor_bridge_game_handle handle, uint32_t entityId,
                                            uint32_t entityGeneration, const char* componentType) const -> bool;
        [[nodiscard]] auto removeComponentProperty(noi_engine_editor_bridge_game_handle handle, uint32_t entityId,
                                                     uint32_t entityGeneration, const char* componentType,
                                                     const char* propertyName) const -> bool;
        [[nodiscard]] auto removeMaterialProperty(noi_engine_editor_bridge_game_handle handle, uint32_t materialId,
                                                    uint32_t materialGeneration,
                                                    const char* propertyName) const -> bool;

    private:
        using init_gl_fn = void (*)(noi_engine_editor_bridge_gl_proc_loader);
        using create_fn = noi_engine_editor_bridge_game_handle (*)(int, int, const char*);
        using destroy_fn = void (*)(noi_engine_editor_bridge_game_handle);
        using run_fn = void (*)(noi_engine_editor_bridge_game_handle);
        using on_resize_fn = void (*)(noi_engine_editor_bridge_game_handle, int, int);
        using set_scene_2d_fn = void (*)(noi_engine_editor_bridge_game_handle, const char*);
        using load_scripts_fn = int (*)(noi_engine_editor_bridge_game_handle, const char*);
        using engine_version_fn = const char* (*)();
        using api_version_fn = int (*)();
        using enumerate_resources_fn = void (*)(noi_engine_editor_bridge_game_handle,
                                                  noi_engine_editor_bridge_resource_entry_callback, void*);
        using enumerate_entities_fn = void (*)(noi_engine_editor_bridge_game_handle,
                                                noi_engine_editor_bridge_entity_entry_callback, void*);
        using enumerate_component_properties_fn = void (*)(noi_engine_editor_bridge_game_handle, uint32_t, uint32_t,
                                                             const char*,
                                                             noi_engine_editor_bridge_property_entry_callback, void*);
        using set_component_property_fn = int (*)(noi_engine_editor_bridge_game_handle, uint32_t, uint32_t,
                                                    const char*, const char*,
                                                    noi_engine_editor_bridge_property_value);
        using add_component_fn = int (*)(noi_engine_editor_bridge_game_handle, uint32_t, uint32_t, const char*);
        using enumerate_material_properties_fn = void (*)(noi_engine_editor_bridge_game_handle, uint32_t, uint32_t,
                                                             noi_engine_editor_bridge_property_entry_callback, void*);
        using set_material_property_fn = int (*)(noi_engine_editor_bridge_game_handle, uint32_t, uint32_t,
                                                   const char*, noi_engine_editor_bridge_property_value);
        using set_key_pressed_fn = void (*)(noi_engine_editor_bridge_game_handle, int);
        using set_key_released_fn = void (*)(noi_engine_editor_bridge_game_handle, int);
        using release_all_keys_fn = void (*)(noi_engine_editor_bridge_game_handle);
        using reset_timer_fn = void (*)(noi_engine_editor_bridge_game_handle);
        using set_playing_fn = void (*)(noi_engine_editor_bridge_game_handle, int);
        using set_grid_visible_fn = void (*)(noi_engine_editor_bridge_game_handle, int);
        using save_scene_fn = int (*)(noi_engine_editor_bridge_game_handle, const char*);
        using create_entity_fn = noi_engine_editor_bridge_entity_ref (*)(noi_engine_editor_bridge_game_handle,
                                                                          const char*);
        using destroy_entity_fn = int (*)(noi_engine_editor_bridge_game_handle, uint32_t, uint32_t);
        using duplicate_entity_fn = noi_engine_editor_bridge_entity_ref (*)(noi_engine_editor_bridge_game_handle,
                                                                             uint32_t, uint32_t, const char*);
        using remove_component_fn = int (*)(noi_engine_editor_bridge_game_handle, uint32_t, uint32_t, const char*);
        using remove_component_property_fn = int (*)(noi_engine_editor_bridge_game_handle, uint32_t, uint32_t,
                                                        const char*, const char*);
        using remove_material_property_fn = int (*)(noi_engine_editor_bridge_game_handle, uint32_t, uint32_t,
                                                       const char*);

        QLibrary m_engineLibrary;
        QLibrary m_library;
        init_gl_fn m_initGl{nullptr};
        set_playing_fn m_setPlaying{nullptr};
        create_fn m_create{nullptr};
        destroy_fn m_destroy{nullptr};
        run_fn m_run{nullptr};
        on_resize_fn m_onResize{nullptr};
        set_scene_2d_fn m_setScene2d{nullptr};
        load_scripts_fn m_loadScripts{nullptr};
        engine_version_fn m_engineVersion{nullptr};
        enumerate_resources_fn m_enumerateResources{nullptr};
        enumerate_entities_fn m_enumerateEntities{nullptr};
        enumerate_component_properties_fn m_enumerateComponentProperties{nullptr};
        set_component_property_fn m_setComponentProperty{nullptr};
        add_component_fn m_addComponent{nullptr};
        enumerate_material_properties_fn m_enumerateMaterialProperties{nullptr};
        set_material_property_fn m_setMaterialProperty{nullptr};
        set_key_pressed_fn m_setKeyPressed{nullptr};
        set_key_released_fn m_setKeyReleased{nullptr};
        release_all_keys_fn m_releaseAllKeys{nullptr};
        reset_timer_fn m_resetTimer{nullptr};
        set_grid_visible_fn m_setGridVisible{nullptr};
        save_scene_fn m_saveScene{nullptr};
        create_entity_fn m_createEntity{nullptr};
        destroy_entity_fn m_destroyEntity{nullptr};
        duplicate_entity_fn m_duplicateEntity{nullptr};
        remove_component_fn m_removeComponent{nullptr};
        remove_component_property_fn m_removeComponentProperty{nullptr};
        remove_material_property_fn m_removeMaterialProperty{nullptr};
    };
}
