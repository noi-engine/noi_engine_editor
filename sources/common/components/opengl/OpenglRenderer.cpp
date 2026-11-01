#include "OpenglView.hpp"
#include "OpenglRenderer.hpp"
#include <QOpenGLFramebufferObject>
#include <QOpenGLFunctions>
#include <QDir>
#include <QFileInfo>
#include <stdexcept>
#include <QDebug>
#include <QQuickWindow>
#include <QVariantMap>

namespace noi_engine_editor
{
    namespace
    {
        auto resourceTypeName(const noi_engine_editor_bridge_resource_type type) -> QString
        {
            switch (type)
            {
                case NOI_ENGINE_EDITOR_BRIDGE_RESOURCE_MESH: return QStringLiteral("mesh");
                case NOI_ENGINE_EDITOR_BRIDGE_RESOURCE_SCRIPT: return QStringLiteral("script");
                case NOI_ENGINE_EDITOR_BRIDGE_RESOURCE_SHADER: return QStringLiteral("shader");
                case NOI_ENGINE_EDITOR_BRIDGE_RESOURCE_TEXTURE: return QStringLiteral("texture");
                case NOI_ENGINE_EDITOR_BRIDGE_RESOURCE_MATERIAL: return QStringLiteral("material");
            }
            return QStringLiteral("unknown");
        }
    }

    static auto getSceneResourceDotPath(const QString& resourcesDirPath, const QString& scenePath) -> QString
    {
        const auto cleanFilePath = QFileInfo(scenePath).canonicalFilePath();
        const auto cleanResourcesPath = QDir(resourcesDirPath).canonicalPath();

        if (!cleanFilePath.startsWith(cleanResourcesPath))
        {
            throw std::invalid_argument("Invalid resources Scene Path = " + scenePath.toStdString());
        }

        const QDir resourcesDir(cleanResourcesPath);
        return resourcesDir.relativeFilePath(cleanFilePath);
    }

    OpenGLRenderer::OpenGLRenderer(const int gameWidth, const int gameHeight, const QString& resourcesPath,
                                   const QString& scriptsLibraryPath, const QString& bridgeLibraryPath,
                                   const QString& engineLibraryPath, const QString& engineVersion) :
        m_gameWidth(gameWidth),
        m_gameHeight(gameHeight),
        m_resourcesPath(
            resourcesPath),
        m_scriptsLibraryPath(scriptsLibraryPath),
        m_bridgeLibraryPath(bridgeLibraryPath),
        m_engineLibraryPath(engineLibraryPath),
        m_engineVersion(engineVersion)
    {
        this->ensureBridgeLoaded();
    }

    void OpenGLRenderer::ensureBridgeLoaded()
    {
        if (this->m_gameHandle)
        {
            return;
        }

        if (!m_bridge.load(this->m_bridgeLibraryPath, this->m_engineLibraryPath))
        {
            if (!m_bridgeLoadWarned)
            {
                m_bridgeLoadWarned = true;
                qWarning() << "[OpenGLRenderer] No usable editor bridge for noi_engine" << this->m_engineVersion <<
                    "yet - will keep retrying (the bridge may still be downloading).";
            }
            return;
        }

        m_bridge.initGl(
            [](const char* name) -> void*
            {
                const auto* currentCtx = QOpenGLContext::currentContext();
                if (!currentCtx) return nullptr;

                return reinterpret_cast<void*>(currentCtx->getProcAddress(name));
            });

        this->m_gameHandle = m_bridge.create(this->m_gameWidth, this->m_gameHeight, this->m_resourcesPath);
    }

    OpenGLRenderer::~OpenGLRenderer()
    {
        // Qt Quick also tears renderer nodes down via QQuickWindowPrivate::cleanupNodesOnShutdown()
        // (both on window/app close and on plain item removal, e.g. navigating away from the editor
        // page), and at that point there is no current OpenGL context. The bridge/engine release GPU
        // resources (buffers, shaders, textures) on destruction, which segfaults without a live context,
        // so skip it in that case - the process/window teardown reclaims the GPU resources anyway.
        if (m_gameHandle && m_bridge.isLoaded() && QOpenGLContext::currentContext())
        {
            m_bridge.destroy(m_gameHandle);
        }
    }

    void OpenGLRenderer::render()
    {
        if (!this->m_gameHandle)
        {
            this->ensureBridgeLoaded();
        }

        if (this->m_gameHandle)
        {
            if (auto* f = QOpenGLContext::currentContext()->functions())
            {
                f->glViewport(0, 0, this->m_width, this->m_height);
            }

            m_bridge.run(this->m_gameHandle);

            if (m_wasPlaying)
            {
                // Keep ticking every frame while playing. This is QQuickFramebufferObject::
                // Renderer::update() (schedules the next frame, paced by vsync, entirely on this
                // render thread) - NOT the item's update() used everywhere else in this file.
                this->update();
            }
        }
    }

    QOpenGLFramebufferObject* OpenGLRenderer::createFramebufferObject(const QSize& size)
    {
        QOpenGLFramebufferObjectFormat format;

        format.setAttachment(QOpenGLFramebufferObject::CombinedDepthStencil);
        format.setInternalTextureFormat(GL_RGBA8);

        return new QOpenGLFramebufferObject(size, format);
    }

    void OpenGLRenderer::resourceEntryCallback(void* userData, const noi_engine_editor_bridge_resource_type type,
                                                const char* label, const uint32_t id, const uint32_t generation)
    {
        auto* list = static_cast<QVariantList*>(userData);
        list->append(QVariantMap{
            {QStringLiteral("type"), resourceTypeName(type)},
            {QStringLiteral("label"), QString::fromUtf8(label)},
            {QStringLiteral("id"), id},
            {QStringLiteral("generation"), generation},
        });
    }

    void OpenGLRenderer::entityEntryCallback(void* userData, const uint32_t entityId, const uint32_t entityGeneration,
                                              const char* name, const char* componentTypesCsv)
    {
        auto* list = static_cast<QVariantList*>(userData);
        const auto csv = QString::fromUtf8(componentTypesCsv);
        const auto componentTypes = csv.isEmpty() ? QStringList{} : csv.split(QLatin1Char(','));

        list->append(QVariantMap{
            {QStringLiteral("id"), entityId},
            {QStringLiteral("generation"), entityGeneration},
            {QStringLiteral("name"), QString::fromUtf8(name)},
            {QStringLiteral("componentTypes"), componentTypes},
        });
    }

    void OpenGLRenderer::propertyEntryCallback(void* userData, const char* propertyName,
                                                const noi_engine_editor_bridge_property_value value,
                                                const int readOnly)
    {
        auto* list = static_cast<QVariantList*>(userData);
        QVariant qvalue;
        QString typeName;
        QString resourceType;

        switch (value.type)
        {
            case NOI_ENGINE_EDITOR_BRIDGE_PROPERTY_FLOAT:
                typeName = QStringLiteral("float");
                qvalue = value.number[0];
                break;
            case NOI_ENGINE_EDITOR_BRIDGE_PROPERTY_VEC3:
                typeName = QStringLiteral("vec3");
                qvalue = QVariantList{value.number[0], value.number[1], value.number[2]};
                break;
            case NOI_ENGINE_EDITOR_BRIDGE_PROPERTY_VEC4:
                typeName = QStringLiteral("vec4");
                qvalue = QVariantList{value.number[0], value.number[1], value.number[2], value.number[3]};
                break;
            case NOI_ENGINE_EDITOR_BRIDGE_PROPERTY_STRING:
                typeName = QStringLiteral("string");
                qvalue = QString::fromUtf8(value.text ? value.text : "");
                break;
            case NOI_ENGINE_EDITOR_BRIDGE_PROPERTY_BOOL:
                typeName = QStringLiteral("bool");
                qvalue = static_cast<bool>(value.flag);
                break;
            case NOI_ENGINE_EDITOR_BRIDGE_PROPERTY_RESOURCE_REF:
                typeName = QStringLiteral("resourceRef");
                qvalue = QString::fromUtf8(value.text ? value.text : "");
                resourceType = resourceTypeName(value.resource_type);
                break;
        }

        list->append(QVariantMap{
            {QStringLiteral("name"), QString::fromUtf8(propertyName)},
            {QStringLiteral("type"), typeName},
            {QStringLiteral("value"), qvalue},
            {QStringLiteral("readOnly"), readOnly != 0},
            {QStringLiteral("resourceType"), resourceType},
        });
    }

    void OpenGLRenderer::applyPendingPropertyEdits(OpenGLView* view)
    {
        if (!this->m_gameHandle)
        {
            return;
        }

        const auto edits = view->takePendingPropertyEdits();
        for (const auto& edit : edits)
        {
            noi_engine_editor_bridge_property_value value{};

            if (edit.propertyType == QStringLiteral("float"))
            {
                value.type = NOI_ENGINE_EDITOR_BRIDGE_PROPERTY_FLOAT;
                value.number[0] = edit.value.toFloat();
            }
            else if (edit.propertyType == QStringLiteral("vec3"))
            {
                const auto components = edit.value.toList();
                value.type = NOI_ENGINE_EDITOR_BRIDGE_PROPERTY_VEC3;
                value.number[0] = components.value(0).toFloat();
                value.number[1] = components.value(1).toFloat();
                value.number[2] = components.value(2).toFloat();
            }
            else if (edit.propertyType == QStringLiteral("vec4"))
            {
                const auto components = edit.value.toList();
                value.type = NOI_ENGINE_EDITOR_BRIDGE_PROPERTY_VEC4;
                value.number[0] = components.value(0).toFloat();
                value.number[1] = components.value(1).toFloat();
                value.number[2] = components.value(2).toFloat();
                value.number[3] = components.value(3).toFloat();
            }
            else if (edit.propertyType == QStringLiteral("string") || edit.propertyType == QStringLiteral("resourceRef"))
            {
                value.type = edit.propertyType == QStringLiteral("string")
                    ? NOI_ENGINE_EDITOR_BRIDGE_PROPERTY_STRING
                    : NOI_ENGINE_EDITOR_BRIDGE_PROPERTY_RESOURCE_REF;
                const auto text = edit.value.toString().toUtf8();
                value.text = text.constData();
                if (!m_bridge.setComponentProperty(this->m_gameHandle, edit.entityId, edit.entityGeneration,
                                                    edit.componentType.toUtf8().constData(),
                                                    edit.propertyName.toUtf8().constData(), value))
                {
                    qWarning() << "[OpenGLRenderer] Failed to set" << edit.componentType << "." << edit.propertyName;
                }
                continue; // `text` (the QByteArray) must outlive the call; handled inline above
            }
            else if (edit.propertyType == QStringLiteral("bool"))
            {
                value.type = NOI_ENGINE_EDITOR_BRIDGE_PROPERTY_BOOL;
                value.flag = edit.value.toBool() ? 1 : 0;
            }
            else
            {
                continue;
            }

            if (!m_bridge.setComponentProperty(this->m_gameHandle, edit.entityId, edit.entityGeneration,
                                                edit.componentType.toUtf8().constData(),
                                                edit.propertyName.toUtf8().constData(), value))
            {
                qWarning() << "[OpenGLRenderer] Failed to set" << edit.componentType << "." << edit.propertyName;
            }
        }
    }

    void OpenGLRenderer::applyPendingComponentAdds(OpenGLView* view)
    {
        if (!this->m_gameHandle)
        {
            return;
        }

        const auto adds = view->takePendingComponentAdds();
        for (const auto& add : adds)
        {
            if (!m_bridge.addComponent(this->m_gameHandle, add.entityId, add.entityGeneration,
                                        add.componentType.toUtf8().constData()))
            {
                qWarning() << "[OpenGLRenderer] Failed to add component" << add.componentType;
            }
        }
    }

    void OpenGLRenderer::applyPendingComponentRemoves(OpenGLView* view)
    {
        if (!this->m_gameHandle)
        {
            return;
        }

        const auto removes = view->takePendingComponentRemoves();
        for (const auto& remove : removes)
        {
            if (!m_bridge.removeComponent(this->m_gameHandle, remove.entityId, remove.entityGeneration,
                                           remove.componentType.toUtf8().constData()))
            {
                qWarning() << "[OpenGLRenderer] Failed to remove component" << remove.componentType;
            }
        }
    }

    void OpenGLRenderer::applyPendingComponentPropertyRemoves(OpenGLView* view)
    {
        if (!this->m_gameHandle)
        {
            return;
        }

        const auto removes = view->takePendingComponentPropertyRemoves();
        for (const auto& remove : removes)
        {
            if (!m_bridge.removeComponentProperty(this->m_gameHandle, remove.entityId, remove.entityGeneration,
                                                   remove.componentType.toUtf8().constData(),
                                                   remove.propertyName.toUtf8().constData()))
            {
                qWarning() << "[OpenGLRenderer] Failed to remove property" << remove.propertyName;
            }
        }
    }

    void OpenGLRenderer::applyPendingEntityCreates(OpenGLView* view)
    {
        if (!this->m_gameHandle)
        {
            return;
        }

        const auto creates = view->takePendingEntityCreates();
        for (const auto& create : creates)
        {
            const auto ref = m_bridge.createEntity(this->m_gameHandle, create.name);
            view->notifyEntityCreated(ref.id, ref.generation);
        }
    }

    void OpenGLRenderer::applyPendingEntityDestroys(OpenGLView* view)
    {
        if (!this->m_gameHandle)
        {
            return;
        }

        // Clearing a stale Inspector selection when its entity gets destroyed is the QML layer's
        // job (ProjectEditorPage.qml sets selectedEntity = null before queuing this) - hasInspectedEntity
        // is a two-way alias bound to `selectedEntity !== null` there, and writing it directly
        // from here would sever that binding for good, not just for this one frame.
        const auto destroys = view->takePendingEntityDestroys();
        for (const auto& destroy : destroys)
        {
            if (!m_bridge.destroyEntity(this->m_gameHandle, destroy.entityId, destroy.entityGeneration))
            {
                qWarning() << "[OpenGLRenderer] Failed to destroy entity" << destroy.entityId;
            }
        }
    }

    void OpenGLRenderer::applyPendingEntityDuplicates(OpenGLView* view)
    {
        if (!this->m_gameHandle)
        {
            return;
        }

        const auto duplicates = view->takePendingEntityDuplicates();
        for (const auto& duplicate : duplicates)
        {
            const auto ref = m_bridge.duplicateEntity(this->m_gameHandle, duplicate.entityId,
                                                       duplicate.entityGeneration, duplicate.newName);
            view->notifyEntityCreated(ref.id, ref.generation);
        }
    }

    void OpenGLRenderer::applyPendingMaterialPropertyEdits(OpenGLView* view)
    {
        if (!this->m_gameHandle)
        {
            return;
        }

        const auto edits = view->takePendingMaterialPropertyEdits();
        for (const auto& edit : edits)
        {
            noi_engine_editor_bridge_property_value value{};

            if (edit.propertyType == QStringLiteral("float"))
            {
                value.type = NOI_ENGINE_EDITOR_BRIDGE_PROPERTY_FLOAT;
                value.number[0] = edit.value.toFloat();
            }
            else if (edit.propertyType == QStringLiteral("vec4"))
            {
                const auto components = edit.value.toList();
                value.type = NOI_ENGINE_EDITOR_BRIDGE_PROPERTY_VEC4;
                value.number[0] = components.value(0).toFloat();
                value.number[1] = components.value(1).toFloat();
                value.number[2] = components.value(2).toFloat();
                value.number[3] = components.value(3).toFloat();
            }
            else if (edit.propertyType == QStringLiteral("resourceRef"))
            {
                value.type = NOI_ENGINE_EDITOR_BRIDGE_PROPERTY_RESOURCE_REF;
                const auto text = edit.value.toString().toUtf8();
                value.text = text.constData();
                if (!m_bridge.setMaterialProperty(this->m_gameHandle, edit.materialId, edit.materialGeneration,
                                                   edit.propertyName.toUtf8().constData(), value))
                {
                    qWarning() << "[OpenGLRenderer] Failed to set material property" << edit.propertyName;
                }
                continue; // `text` (the QByteArray) must outlive the call; handled inline above
            }
            else
            {
                continue;
            }

            if (!m_bridge.setMaterialProperty(this->m_gameHandle, edit.materialId, edit.materialGeneration,
                                               edit.propertyName.toUtf8().constData(), value))
            {
                qWarning() << "[OpenGLRenderer] Failed to set material property" << edit.propertyName;
            }
        }
    }

    void OpenGLRenderer::applyPendingMaterialPropertyRemoves(OpenGLView* view)
    {
        if (!this->m_gameHandle)
        {
            return;
        }

        const auto removes = view->takePendingMaterialPropertyRemoves();
        for (const auto& remove : removes)
        {
            if (!m_bridge.removeMaterialProperty(this->m_gameHandle, remove.materialId, remove.materialGeneration,
                                                  remove.propertyName.toUtf8().constData()))
            {
                qWarning() << "[OpenGLRenderer] Failed to remove material property" << remove.propertyName;
            }
        }
    }

    void OpenGLRenderer::applyPendingKeyEvents(OpenGLView* view)
    {
        if (!this->m_gameHandle)
        {
            return;
        }

        const auto events = view->takePendingKeyEvents();
        for (const auto& event : events)
        {
            if (event.pressed)
            {
                m_bridge.setKeyPressed(this->m_gameHandle, event.keyCode);
            }
            else
            {
                m_bridge.setKeyReleased(this->m_gameHandle, event.keyCode);
            }
        }
    }

    void OpenGLRenderer::applyPendingSceneSaves(OpenGLView* view)
    {
        if (!this->m_gameHandle)
        {
            return;
        }

        const auto saves = view->takePendingSceneSaves();
        for (const auto& save : saves)
        {
            const auto success = m_bridge.saveScene(this->m_gameHandle, save.targetPath);
            view->confirmSceneSaved(success);
        }
    }

    void OpenGLRenderer::updatePlayState(OpenGLView* view)
    {
        if (!this->m_gameHandle)
        {
            return;
        }

        if (view->stopRequested())
        {
            // Final tick before actually stopping: apply whatever key releases were queued, release
            // anything the Qt-side tracking might have missed (e.g. focus lost mid-press), then
            // reload the scene from disk - set_scene_2d() already fully discards the live world and
            // rebuilds it from the .scene resource, which is exactly "reset to the pre-play state".
            // Only once all of that is done do we let the editor know it's safe to unlock editing -
            // "the system stops first".
            this->applyPendingKeyEvents(view);
            m_bridge.releaseAllKeys(this->m_gameHandle);
            if (!m_currentPath.isEmpty())
            {
                const auto relativeScenePath = getSceneResourceDotPath(this->m_resourcesPath, this->m_currentPath);
                m_bridge.setScene2d(this->m_gameHandle, relativeScenePath);
                m_bridge.onResize(this->m_gameHandle, m_width, m_height);
            }
            m_wasPlaying = false;
            view->confirmStopped();
            return;
        }

        if (view->isPlaying() && !m_wasPlaying)
        {
            // Fresh play-start transition: re-sync the bridge's dt timer so the first continuous
            // tick doesn't report however long the scene sat idle in edit mode.
            m_bridge.resetTimer(this->m_gameHandle);
            m_wasPlaying = true;
        }

        this->applyPendingKeyEvents(view);
    }

    QVariantList OpenGLRenderer::buildInspectedMaterialProperties(OpenGLView* view)
    {
        QVariantList properties;

        if (!this->m_gameHandle || !view->hasInspectedMaterial())
        {
            return properties;
        }

        m_bridge.enumerateMaterialProperties(this->m_gameHandle, view->inspectedMaterialId(),
                                              view->inspectedMaterialGeneration(),
                                              &OpenGLRenderer::propertyEntryCallback, &properties);
        return properties;
    }

    QVariantList OpenGLRenderer::buildInspectedComponents(OpenGLView* view, const QVariantList& loadedEntities)
    {
        QVariantList inspectedComponents;

        if (!this->m_gameHandle || !view->hasInspectedEntity())
        {
            return inspectedComponents;
        }

        const auto targetId = view->inspectedEntityId();
        const auto targetGeneration = view->inspectedEntityGeneration();

        for (const auto& entityVariant : loadedEntities)
        {
            const auto entityMap = entityVariant.toMap();
            if (entityMap.value(QStringLiteral("id")).toUInt() != targetId ||
                entityMap.value(QStringLiteral("generation")).toUInt() != targetGeneration)
            {
                continue;
            }

            const auto componentTypes = entityMap.value(QStringLiteral("componentTypes")).toStringList();
            for (const auto& componentType : componentTypes)
            {
                QVariantList properties;
                m_bridge.enumerateComponentProperties(this->m_gameHandle, targetId, targetGeneration,
                                                       componentType.toUtf8().constData(),
                                                       &OpenGLRenderer::propertyEntryCallback, &properties);
                inspectedComponents.append(QVariantMap{
                    {QStringLiteral("type"), componentType},
                    {QStringLiteral("properties"), properties},
                });
            }
            break;
        }

        return inspectedComponents;
    }

    void OpenGLRenderer::synchronize(QQuickFramebufferObject* item)
    {
        auto* view = static_cast<OpenGLView*>(item);
        const auto dpr = view->window() ? view->window()->devicePixelRatio() : 1.0;
        const auto realWidth = static_cast<int>(view->width() * dpr);
        const auto realHeight = static_cast<int>(view->height() * dpr);

        if (this->m_gameHandle)
        {
            if (this->m_width != realWidth || this->m_height != realHeight)
            {
                this->m_width = realWidth;
                this->m_height = realHeight;
                m_bridge.onResize(this->m_gameHandle, m_width, m_height);
            }

            if (const auto newGeneration = view->scriptsGeneration(); m_scriptsGeneration != newGeneration)
            {
                if (m_bridge.loadScripts(this->m_gameHandle, m_scriptsLibraryPath))
                {
                    m_scriptsGeneration = newGeneration;
                    m_scriptsLoaded = true;
                }
                else if (m_lastWarnedScriptsGeneration != newGeneration)
                {
                    m_lastWarnedScriptsGeneration = newGeneration;
                    qWarning() << "[OpenGLRenderer] Failed to load scripts library:" << m_scriptsLibraryPath
                        << "- will keep retrying; scene preview is unavailable until this succeeds.";
                }
            }
        }

        // Opening a scene before scripts are loaded would let the engine look up an unregistered
        // script by name and crash (std::out_of_range from an internal unordered_map::at). Wait
        // until loadScripts() has succeeded at least once; m_currentPath stays stale so this is
        // retried automatically on the next frame once scripts become available.
        const auto newPath = view->scenePath();
        const auto newReloadToken = view->sceneReloadToken();
        if (m_scriptsLoaded && (m_currentPath != newPath || m_sceneReloadToken != newReloadToken))
        {
            m_currentPath = newPath;
            m_sceneReloadToken = newReloadToken;
            if (!m_currentPath.isEmpty() && this->m_gameHandle)
            {
                const auto relativeScenePath = getSceneResourceDotPath(this->m_resourcesPath, this->m_currentPath);
                m_bridge.setScene2d(this->m_gameHandle, relativeScenePath);
                m_bridge.onResize(this->m_gameHandle, m_width, m_height);
            }
        }

        if (this->m_gameHandle && view->gridVisible() != m_lastPushedGridVisible)
        {
            m_lastPushedGridVisible = view->gridVisible();
            m_bridge.setGridVisible(this->m_gameHandle, m_lastPushedGridVisible);
        }

        this->updatePlayState(view);
        this->applyPendingEntityCreates(view);
        this->applyPendingEntityDuplicates(view);
        this->applyPendingEntityDestroys(view);
        this->applyPendingComponentAdds(view);
        this->applyPendingComponentRemoves(view);
        this->applyPendingComponentPropertyRemoves(view);
        this->applyPendingPropertyEdits(view);
        this->applyPendingMaterialPropertyEdits(view);
        this->applyPendingMaterialPropertyRemoves(view);
        this->applyPendingSceneSaves(view);

        QVariantList loadedResources;
        QVariantList loadedEntities;
        if (this->m_gameHandle)
        {
            m_bridge.enumerateResources(this->m_gameHandle, &OpenGLRenderer::resourceEntryCallback, &loadedResources);
            m_bridge.enumerateEntities(this->m_gameHandle, &OpenGLRenderer::entityEntryCallback, &loadedEntities);
        }
        view->setLoadedResources(loadedResources);
        view->setLoadedEntities(loadedEntities);
        view->setInspectedComponents(this->buildInspectedComponents(view, loadedEntities));
        view->setInspectedMaterialProperties(this->buildInspectedMaterialProperties(view));
    }
}
