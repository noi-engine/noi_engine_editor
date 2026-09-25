#include "OpenglView.hpp"
#include "OpenglRenderer.hpp"

#include <QKeyEvent>
#include <utility>

namespace noi_engine_editor
{
    namespace
    {
        // Maps Qt::Key to noi_engine::key_code's numeric layout (SDL_Scancode-compatible - see
        // noi_engine/core/input/input_codes.hpp). Returns -1 for keys with no mapping (keyboard
        // only, and only the keys a gameplay script would plausibly read, for now).
        int qtKeyToEngineKeyCode(const int qtKey)
        {
            switch (qtKey)
            {
                case Qt::Key_A: return 4;
                case Qt::Key_B: return 5;
                case Qt::Key_C: return 6;
                case Qt::Key_D: return 7;
                case Qt::Key_E: return 8;
                case Qt::Key_F: return 9;
                case Qt::Key_G: return 10;
                case Qt::Key_H: return 11;
                case Qt::Key_I: return 12;
                case Qt::Key_J: return 13;
                case Qt::Key_K: return 14;
                case Qt::Key_L: return 15;
                case Qt::Key_M: return 16;
                case Qt::Key_N: return 17;
                case Qt::Key_O: return 18;
                case Qt::Key_P: return 19;
                case Qt::Key_Q: return 20;
                case Qt::Key_R: return 21;
                case Qt::Key_S: return 22;
                case Qt::Key_T: return 23;
                case Qt::Key_U: return 24;
                case Qt::Key_V: return 25;
                case Qt::Key_W: return 26;
                case Qt::Key_X: return 27;
                case Qt::Key_Y: return 28;
                case Qt::Key_Z: return 29;
                case Qt::Key_1: return 30;
                case Qt::Key_2: return 31;
                case Qt::Key_3: return 32;
                case Qt::Key_4: return 33;
                case Qt::Key_5: return 34;
                case Qt::Key_6: return 35;
                case Qt::Key_7: return 36;
                case Qt::Key_8: return 37;
                case Qt::Key_9: return 38;
                case Qt::Key_0: return 39;
                case Qt::Key_Return: return 40;
                case Qt::Key_Enter: return 40;
                case Qt::Key_Escape: return 41;
                case Qt::Key_Backspace: return 42;
                case Qt::Key_Tab: return 43;
                case Qt::Key_Space: return 44;
                case Qt::Key_F1: return 58;
                case Qt::Key_F2: return 59;
                case Qt::Key_F3: return 60;
                case Qt::Key_F4: return 61;
                case Qt::Key_F5: return 62;
                case Qt::Key_F6: return 63;
                case Qt::Key_F7: return 64;
                case Qt::Key_F8: return 65;
                case Qt::Key_F9: return 66;
                case Qt::Key_F10: return 67;
                case Qt::Key_F11: return 68;
                case Qt::Key_F12: return 69;
                case Qt::Key_Right: return 79;
                case Qt::Key_Left: return 80;
                case Qt::Key_Down: return 81;
                case Qt::Key_Up: return 82;
                // Qt doesn't reliably distinguish left/right modifiers - map to the left variant.
                case Qt::Key_Control: return 224;
                case Qt::Key_Shift: return 225;
                case Qt::Key_Alt: return 226;
                default: return -1;
            }
        }
    }

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

    void OpenGLView::reloadScene()
    {
        ++m_sceneReloadToken;
        update();
    }

    int OpenGLView::sceneReloadToken() const
    {
        return this->m_sceneReloadToken;
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

    bool OpenGLView::gridVisible() const
    {
        return this->m_gridVisible;
    }

    void OpenGLView::setGridVisible(const bool visible)
    {
        if (m_gridVisible == visible)
        {
            return;
        }

        m_gridVisible = visible;
        Q_EMIT gridVisibleChanged();

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

    void OpenGLView::removeComponent(const quint32 entityId, const quint32 entityGeneration,
                                      const QString& componentType)
    {
        m_pendingComponentRemoves.append(PendingComponentRemove{entityId, entityGeneration, componentType});
        update();
    }

    QVector<PendingComponentRemove> OpenGLView::takePendingComponentRemoves()
    {
        auto removes = std::move(m_pendingComponentRemoves);
        m_pendingComponentRemoves.clear();
        return removes;
    }

    void OpenGLView::removeComponentProperty(const quint32 entityId, const quint32 entityGeneration,
                                              const QString& componentType, const QString& propertyName)
    {
        m_pendingComponentPropertyRemoves.append(
            PendingComponentPropertyRemove{entityId, entityGeneration, componentType, propertyName});
        update();
    }

    QVector<PendingComponentPropertyRemove> OpenGLView::takePendingComponentPropertyRemoves()
    {
        auto removes = std::move(m_pendingComponentPropertyRemoves);
        m_pendingComponentPropertyRemoves.clear();
        return removes;
    }

    void OpenGLView::createEntity(const QString& name)
    {
        m_pendingEntityCreates.append(PendingEntityCreate{name});
        update();
    }

    QVector<PendingEntityCreate> OpenGLView::takePendingEntityCreates()
    {
        auto creates = std::move(m_pendingEntityCreates);
        m_pendingEntityCreates.clear();
        return creates;
    }

    void OpenGLView::destroyEntity(const quint32 entityId, const quint32 entityGeneration)
    {
        m_pendingEntityDestroys.append(PendingEntityDestroy{entityId, entityGeneration});
        update();
    }

    QVector<PendingEntityDestroy> OpenGLView::takePendingEntityDestroys()
    {
        auto destroys = std::move(m_pendingEntityDestroys);
        m_pendingEntityDestroys.clear();
        return destroys;
    }

    void OpenGLView::duplicateEntity(const quint32 entityId, const quint32 entityGeneration, const QString& newName)
    {
        m_pendingEntityDuplicates.append(PendingEntityDuplicate{entityId, entityGeneration, newName});
        update();
    }

    QVector<PendingEntityDuplicate> OpenGLView::takePendingEntityDuplicates()
    {
        auto duplicates = std::move(m_pendingEntityDuplicates);
        m_pendingEntityDuplicates.clear();
        return duplicates;
    }

    void OpenGLView::notifyEntityCreated(const quint32 entityId, const quint32 entityGeneration)
    {
        Q_EMIT entityCreated(entityId, entityGeneration);
    }

    bool OpenGLView::hasInspectedMaterial() const
    {
        return this->m_hasInspectedMaterial;
    }

    void OpenGLView::setHasInspectedMaterial(const bool hasMaterial)
    {
        if (m_hasInspectedMaterial == hasMaterial)
        {
            return;
        }

        m_hasInspectedMaterial = hasMaterial;
        Q_EMIT inspectedMaterialChanged();

        update();
    }

    quint32 OpenGLView::inspectedMaterialId() const
    {
        return this->m_inspectedMaterialId;
    }

    void OpenGLView::setInspectedMaterialId(const quint32 materialId)
    {
        if (m_inspectedMaterialId == materialId)
        {
            return;
        }

        m_inspectedMaterialId = materialId;
        Q_EMIT inspectedMaterialChanged();

        update();
    }

    quint32 OpenGLView::inspectedMaterialGeneration() const
    {
        return this->m_inspectedMaterialGeneration;
    }

    void OpenGLView::setInspectedMaterialGeneration(const quint32 materialGeneration)
    {
        if (m_inspectedMaterialGeneration == materialGeneration)
        {
            return;
        }

        m_inspectedMaterialGeneration = materialGeneration;
        Q_EMIT inspectedMaterialChanged();

        update();
    }

    QVariantList OpenGLView::inspectedMaterialProperties() const
    {
        return this->m_inspectedMaterialProperties;
    }

    void OpenGLView::setInspectedMaterialProperties(const QVariantList& properties)
    {
        if (m_inspectedMaterialProperties == properties)
        {
            return;
        }

        m_inspectedMaterialProperties = properties;
        Q_EMIT inspectedMaterialPropertiesChanged();
    }

    void OpenGLView::setMaterialProperty(const quint32 materialId, const quint32 materialGeneration,
                                          const QString& propertyName, const QString& propertyType,
                                          const QVariant& value)
    {
        m_pendingMaterialPropertyEdits.append(PendingMaterialPropertyEdit{
            materialId, materialGeneration, propertyName, propertyType, value});

        update(); // there's no continuous render loop - nudge one so synchronize() applies this promptly
    }

    QVector<PendingMaterialPropertyEdit> OpenGLView::takePendingMaterialPropertyEdits()
    {
        auto edits = std::move(m_pendingMaterialPropertyEdits);
        m_pendingMaterialPropertyEdits.clear();
        return edits;
    }

    void OpenGLView::removeMaterialProperty(const quint32 materialId, const quint32 materialGeneration,
                                             const QString& propertyName)
    {
        m_pendingMaterialPropertyRemoves.append(PendingMaterialPropertyRemove{materialId, materialGeneration, propertyName});
        update();
    }

    QVector<PendingMaterialPropertyRemove> OpenGLView::takePendingMaterialPropertyRemoves()
    {
        auto removes = std::move(m_pendingMaterialPropertyRemoves);
        m_pendingMaterialPropertyRemoves.clear();
        return removes;
    }

    bool OpenGLView::isPlaying() const
    {
        return m_playing;
    }

    void OpenGLView::setPlaying(const bool playing)
    {
        if (playing)
        {
            if (m_playing)
            {
                return;
            }

            m_playing = true;
            Q_EMIT playingChanged();
            forceActiveFocus();
            update();
        }
        else
        {
            if (!m_playing || m_stopRequested)
            {
                return;
            }

            m_stopRequested = true;
            for (const auto qtKey : std::as_const(m_pressedQtKeys))
            {
                if (const auto keyCode = qtKeyToEngineKeyCode(qtKey); keyCode >= 0)
                {
                    m_pendingKeyEvents.append(PendingKeyEvent{keyCode, false});
                }
            }
            m_pressedQtKeys.clear();
            update(); // nudge one final frame so synchronize() can apply the releases and confirm the stop
        }
    }

    bool OpenGLView::stopRequested() const
    {
        return m_stopRequested;
    }

    QVector<PendingKeyEvent> OpenGLView::takePendingKeyEvents()
    {
        auto events = std::move(m_pendingKeyEvents);
        m_pendingKeyEvents.clear();
        return events;
    }

    void OpenGLView::confirmStopped()
    {
        m_stopRequested = false;

        if (!m_playing)
        {
            return;
        }

        m_playing = false;
        Q_EMIT playingChanged();
    }

    void OpenGLView::saveScene()
    {
        if (m_scenePath.isEmpty())
        {
            return;
        }

        m_pendingSceneSaves.append(PendingSceneSave{m_scenePath});
        update();
    }

    QVector<PendingSceneSave> OpenGLView::takePendingSceneSaves()
    {
        auto saves = std::move(m_pendingSceneSaves);
        m_pendingSceneSaves.clear();
        return saves;
    }

    void OpenGLView::confirmSceneSaved(const bool success)
    {
        Q_EMIT sceneSaved(success);
    }

    void OpenGLView::queueKeyEvent(const int keyCode, const bool pressed)
    {
        if (keyCode < 0)
        {
            return;
        }

        m_pendingKeyEvents.append(PendingKeyEvent{keyCode, pressed});
        update(); // there's no continuous render loop yet at this point - nudge one
    }

    void OpenGLView::keyPressEvent(QKeyEvent* event)
    {
        if (!m_playing || event->isAutoRepeat())
        {
            QQuickFramebufferObject::keyPressEvent(event);
            return;
        }

        const auto keyCode = qtKeyToEngineKeyCode(event->key());
        if (keyCode >= 0)
        {
            m_pressedQtKeys.insert(event->key());
            queueKeyEvent(keyCode, true);
        }
        event->accept();
    }

    void OpenGLView::keyReleaseEvent(QKeyEvent* event)
    {
        if (!m_playing || event->isAutoRepeat())
        {
            QQuickFramebufferObject::keyReleaseEvent(event);
            return;
        }

        const auto keyCode = qtKeyToEngineKeyCode(event->key());
        if (keyCode >= 0)
        {
            m_pressedQtKeys.remove(event->key());
            queueKeyEvent(keyCode, false);
        }
        event->accept();
    }

    QQuickFramebufferObject::Renderer* OpenGLView::createRenderer() const
    {
        return new OpenGLRenderer(this->m_gameWidth, this->m_gameHeight, this->resourcesPath(), this->scriptsLibraryPath(),
                                  this->bridgeLibraryPath(), this->engineVersion());
    }
}