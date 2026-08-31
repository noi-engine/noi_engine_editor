#pragma once

#include <QString>
#include <QQuickFramebufferObject>

#include <memory>
#include "OpenglNoiEngineGame.hpp"

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
                                 const QString& scriptsLibraryPath);
        ~OpenGLRenderer() override = default;

    private:
        int m_width{};
        int m_height{};
        QString m_currentPath{};
        QString m_resourcesPath{};
        QString m_scriptsLibraryPath{};
        int m_scriptsGeneration{-1};
        std::unique_ptr<OpenglNoiEngineGame> m_game{nullptr};
    };
}
