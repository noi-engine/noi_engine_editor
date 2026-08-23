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
        explicit OpenGLRenderer(const QString& resourcesPath);
        ~OpenGLRenderer() override = default;

    private:
        int m_width{};
        int m_height{};
        QString m_currentPath{};
        QString m_resourcesPath{};
        std::unique_ptr<OpenglNoiEngineGame> m_game{nullptr};
    };
}
