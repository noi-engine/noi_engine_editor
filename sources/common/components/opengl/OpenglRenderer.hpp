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
        OpenGLRenderer();
        ~OpenGLRenderer() override = default;

    private:
        int m_width{};
        int m_height{};
        QString m_currentPath{};
        std::unique_ptr<OpenglNoiEngineGame> m_game{nullptr};
    };
}
