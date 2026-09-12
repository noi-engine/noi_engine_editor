#pragma once

#include <QString>
#include <QQuickFramebufferObject>
#include <QVariantList>

#include "PreviewBridgeLoader.hpp"

namespace noi_engine_editor
{
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
        PreviewBridgeLoader m_bridge{};
        noi_engine_editor_bridge_game_handle m_gameHandle{nullptr};
    };
}
