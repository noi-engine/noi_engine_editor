#pragma once

#include <QOpenGLFramebufferObjectFormat>
#include <QOpenGLFunctions>
#include <QQuickFramebufferObject>

namespace noi_engine_editor
{
    class OpenGLRenderer final : public QQuickFramebufferObject::Renderer
    {
    protected:
        void render() override;

    public:
        OpenGLRenderer();


        QOpenGLFramebufferObject* createFramebufferObject(const QSize& size) override;
    };
}
