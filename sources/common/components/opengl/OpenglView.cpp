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

    int OpenGLView::gameWidth() const
    {
        return this->m_gameWidth;
    }

    void OpenGLView::setGameWidth(int width)
    {
        if (m_gameWidth == width)
        {
            return;
        }

        m_gameWidth = width;
        Q_EMIT gameWidthChanged();

        update();
    }

    int OpenGLView::gameHeight() const
    {
        return this->m_gameHeight;
    }

    void OpenGLView::setGameHeight(int height)
    {
        if (m_gameHeight == height)
        {
            return;
        }

        m_gameHeight = height;
        Q_EMIT gameHeightChanged();

        update();
    }

    QQuickFramebufferObject::Renderer* OpenGLView::createRenderer() const
    {
        return new OpenGLRenderer(this->m_gameWidth, this->m_gameHeight, this->resourcesPath());
    }
}