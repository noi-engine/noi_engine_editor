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

    int OpenGLView::gameWidth() const
    {
        return m_gameWidth;
    }

    void OpenGLView::setGameWidth(int w)
    {
        if (m_gameWidth == w)
        {
            return;
        }

        m_gameWidth = w;
        Q_EMIT gameWidthChanged();
        update();
    }

    int OpenGLView::gameHeight() const
    {
        return m_gameHeight;
    }

    void OpenGLView::setGameHeight(int h)
    {
        if (m_gameHeight == h)
        {
            return;
        }

        m_gameHeight = h;
        Q_EMIT gameHeightChanged();
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
        return new OpenGLRenderer(this->gameHeight(), this->gameHeight(), this->resourcesPath());
    }
}
