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
                                   const QString& engineVersion) :
        m_gameWidth(gameWidth),
        m_gameHeight(gameHeight),
        m_resourcesPath(
            resourcesPath),
        m_scriptsLibraryPath(scriptsLibraryPath),
        m_bridgeLibraryPath(bridgeLibraryPath),
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

        if (!m_bridge.load(this->m_bridgeLibraryPath))
        {
            if (!m_bridgeLoadWarned)
            {
                m_bridgeLoadWarned = true;
                qWarning() << "[OpenGLRenderer] No usable noi_engine preview bridge for engine version" <<
                    this->m_engineVersion <<
                    "yet - will keep retrying (the project may still be building).";
            }
            return;
        }

        if (const auto loadedVersion = m_bridge.engineVersion(); loadedVersion != this->m_engineVersion)
        {
            qWarning() << "[OpenGLRenderer] Preview bridge at" << this->m_bridgeLibraryPath << "reports engine version"
                << loadedVersion << "but the project declares" << this->m_engineVersion <<
                "- the download may be corrupted.";
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
        if (const auto newPath = view->scenePath(); m_scriptsLoaded && m_currentPath != newPath)
        {
            m_currentPath = newPath;
            if (!m_currentPath.isEmpty() && this->m_gameHandle)
            {
                const auto relativeScenePath = getSceneResourceDotPath(this->m_resourcesPath, this->m_currentPath);
                m_bridge.setScene2d(this->m_gameHandle, relativeScenePath);
                m_bridge.onResize(this->m_gameHandle, m_width, m_height);
            }
        }

        QVariantList loadedResources;
        if (this->m_gameHandle)
        {
            m_bridge.enumerateResources(this->m_gameHandle, &OpenGLRenderer::resourceEntryCallback, &loadedResources);
        }
        view->setLoadedResources(loadedResources);
    }
}
