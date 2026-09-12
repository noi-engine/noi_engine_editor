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

    QString OpenGLView::scriptsLibraryPath() const
    {
        return this->m_scriptsLibraryPath;
    }

    void OpenGLView::setScriptsLibraryPath(const QString& path)
    {
        if (m_scriptsLibraryPath == path)
        {
            return;
        }

        m_scriptsLibraryPath = path;
        Q_EMIT scriptsLibraryPathChanged();

        update();
    }

    QString OpenGLView::bridgeLibraryPath() const
    {
        return this->m_bridgeLibraryPath;
    }

    void OpenGLView::setBridgeLibraryPath(const QString& path)
    {
        if (m_bridgeLibraryPath == path)
        {
            return;
        }

        m_bridgeLibraryPath = path;
        Q_EMIT bridgeLibraryPathChanged();

        update();
    }

    int OpenGLView::scriptsGeneration() const
    {
        return this->m_scriptsGeneration;
    }

    void OpenGLView::setScriptsGeneration(const int generation)
    {
        if (m_scriptsGeneration == generation)
        {
            return;
        }

        m_scriptsGeneration = generation;
        Q_EMIT scriptsGenerationChanged();

        update();
    }

    QString OpenGLView::engineVersion() const
    {
        return this->m_engineVersion;
    }

    void OpenGLView::setEngineVersion(const QString& version)
    {
        if (m_engineVersion == version)
        {
            return;
        }

        m_engineVersion = version;
        Q_EMIT engineVersionChanged();

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

    QVariantList OpenGLView::loadedResources() const
    {
        return this->m_loadedResources;
    }

    void OpenGLView::setLoadedResources(const QVariantList& resources)
    {
        if (m_loadedResources == resources)
        {
            return;
        }

        m_loadedResources = resources;
        Q_EMIT loadedResourcesChanged();
    }

    QQuickFramebufferObject::Renderer* OpenGLView::createRenderer() const
    {
        return new OpenGLRenderer(this->m_gameWidth, this->m_gameHeight, this->resourcesPath(), this->scriptsLibraryPath(),
                                  this->bridgeLibraryPath(), this->engineVersion());
    }
}