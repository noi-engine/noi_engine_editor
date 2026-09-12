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

    QVariantList OpenGLView::loadedEntities() const
    {
        return this->m_loadedEntities;
    }

    void OpenGLView::setLoadedEntities(const QVariantList& entities)
    {
        if (m_loadedEntities == entities)
        {
            return;
        }

        m_loadedEntities = entities;
        Q_EMIT loadedEntitiesChanged();
    }

    bool OpenGLView::hasInspectedEntity() const
    {
        return this->m_hasInspectedEntity;
    }

    void OpenGLView::setHasInspectedEntity(const bool hasEntity)
    {
        if (m_hasInspectedEntity == hasEntity)
        {
            return;
        }

        m_hasInspectedEntity = hasEntity;
        Q_EMIT inspectedEntityChanged();

        update();
    }

    quint32 OpenGLView::inspectedEntityId() const
    {
        return this->m_inspectedEntityId;
    }

    void OpenGLView::setInspectedEntityId(const quint32 entityId)
    {
        if (m_inspectedEntityId == entityId)
        {
            return;
        }

        m_inspectedEntityId = entityId;
        Q_EMIT inspectedEntityChanged();

        update();
    }

    quint32 OpenGLView::inspectedEntityGeneration() const
    {
        return this->m_inspectedEntityGeneration;
    }

    void OpenGLView::setInspectedEntityGeneration(const quint32 entityGeneration)
    {
        if (m_inspectedEntityGeneration == entityGeneration)
        {
            return;
        }

        m_inspectedEntityGeneration = entityGeneration;
        Q_EMIT inspectedEntityChanged();

        update();
    }

    QVariantList OpenGLView::inspectedComponents() const
    {
        return this->m_inspectedComponents;
    }

    void OpenGLView::setInspectedComponents(const QVariantList& components)
    {
        if (m_inspectedComponents == components)
        {
            return;
        }

        m_inspectedComponents = components;
        Q_EMIT inspectedComponentsChanged();
    }

    void OpenGLView::setComponentProperty(const quint32 entityId, const quint32 entityGeneration,
                                           const QString& componentType, const QString& propertyName,
                                           const QString& propertyType, const QVariant& value)
    {
        m_pendingPropertyEdits.append(PendingPropertyEdit{
            entityId, entityGeneration, componentType, propertyName, propertyType, value});

        update(); // there's no continuous render loop - nudge one so synchronize() applies this promptly
    }

    QVector<PendingPropertyEdit> OpenGLView::takePendingPropertyEdits()
    {
        auto edits = std::move(m_pendingPropertyEdits);
        m_pendingPropertyEdits.clear();
        return edits;
    }

    void OpenGLView::addComponent(const quint32 entityId, const quint32 entityGeneration,
                                   const QString& componentType)
    {
        m_pendingComponentAdds.append(PendingComponentAdd{entityId, entityGeneration, componentType});

        update(); // there's no continuous render loop - nudge one so synchronize() applies this promptly
    }

    QVector<PendingComponentAdd> OpenGLView::takePendingComponentAdds()
    {
        auto adds = std::move(m_pendingComponentAdds);
        m_pendingComponentAdds.clear();
        return adds;
    }

    QQuickFramebufferObject::Renderer* OpenGLView::createRenderer() const
    {
        return new OpenGLRenderer(this->m_gameWidth, this->m_gameHeight, this->resourcesPath(), this->scriptsLibraryPath(),
                                  this->bridgeLibraryPath(), this->engineVersion());
    }
}