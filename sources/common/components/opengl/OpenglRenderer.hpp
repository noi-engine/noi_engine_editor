#pragma once

#include <QString>
#include <QQuickFramebufferObject>
#include <QVariantList>

#include "PreviewBridgeLoader.hpp"

namespace noi_engine_editor
{
    class OpenGLView;

    class OpenGLRenderer : public QQuickFramebufferObject::Renderer
    {
    protected:
        void render() override;
        void synchronize(QQuickFramebufferObject* item) override;
        QOpenGLFramebufferObject* createFramebufferObject(const QSize& size) override;

    public:
        explicit OpenGLRenderer(int gameWidth, int gameHeight, const QString& resourcesPath,
                                 const QString& scriptsLibraryPath, const QString& bridgeLibraryPath,
                                 const QString& engineVersion);
        ~OpenGLRenderer() override;

        OpenGLRenderer(const OpenGLRenderer&) = delete;
        OpenGLRenderer& operator=(const OpenGLRenderer&) = delete;

    private:
        auto ensureBridgeLoaded() -> void;
        static auto resourceEntryCallback(void* userData, noi_engine_editor_bridge_resource_type type,
                                           const char* label, uint32_t id, uint32_t generation) -> void;
        static auto entityEntryCallback(void* userData, uint32_t entityId, uint32_t entityGeneration,
                                         const char* name, const char* componentTypesCsv) -> void;
        static auto propertyEntryCallback(void* userData, const char* propertyName,
                                           noi_engine_editor_bridge_property_value value, int readOnly) -> void;
        auto applyPendingPropertyEdits(OpenGLView* view) -> void;
        auto applyPendingComponentAdds(OpenGLView* view) -> void;
        auto applyPendingMaterialPropertyEdits(OpenGLView* view) -> void;
        auto applyPendingKeyEvents(OpenGLView* view) -> void;
        auto updatePlayState(OpenGLView* view) -> void;
        auto buildInspectedComponents(OpenGLView* view, const QVariantList& loadedEntities) -> QVariantList;
        auto buildInspectedMaterialProperties(OpenGLView* view) -> QVariantList;

        int m_width{};
        int m_height{};
        int m_gameWidth{};
        int m_gameHeight{};
        QString m_currentPath{};
        QString m_resourcesPath{};
        QString m_scriptsLibraryPath{};
        QString m_bridgeLibraryPath{};
        QString m_engineVersion{};
        int m_scriptsGeneration{-1};
        int m_lastWarnedScriptsGeneration{-2};
        bool m_scriptsLoaded{false};
        bool m_bridgeLoadWarned{false};
        // Render-thread-owned confirmed ticking state - distinct from OpenGLView::isPlaying(),
        // which is the GUI-thread-requested state; see updatePlayState().
        bool m_wasPlaying{false};
        PreviewBridgeLoader m_bridge{};
        noi_engine_editor_bridge_game_handle m_gameHandle{nullptr};
    };
}
