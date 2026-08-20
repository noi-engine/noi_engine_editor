#include "OpenglView.hpp"
#include "OpenglRenderer.hpp"

namespace noi_engine_editor
{
    OpenGLView::OpenGLView(QQuickItem* parent) : QQuickFramebufferObject(parent)
    {
    }

    QString OpenGLView::scenePath() const
    {
        return this->m_scenePath;
    }

    void OpenGLView::setScenePath(const QString& path)
    {
        if (m_scenePath == path)
        {
            return;
        }

        m_scenePath = path;
        Q_EMIT scenePathChanged();

        update();
    }

    QString OpenGLView::resourcesPath() const
    {
        return this->m_resourcesPath;
    }

    void OpenGLView::setResourcesPath(const QString& path)
    {
        if (m_resourcesPath == path)
        {
            return;
        }

        m_resourcesPath = path;
        Q_EMIT resourcesPathChanged();

        update();
    }

    QQuickFramebufferObject::Renderer* OpenGLView::createRenderer() const
    {
        return new OpenGLRenderer(this->resourcesPath());
    }
}
