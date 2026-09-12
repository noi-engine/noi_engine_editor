#include "OpenglView.hpp"
#include "OpenglRenderer.hpp"
#include <QOpenGLFramebufferObject>
#include <QOpenGLFunctions>
#include <QDir>
#include <QFileInfo>
#include <stdexcept>
#include <QDebug>
#include <QQuickWindow>

namespace noi_engine_editor
{
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
        m_resourcesPath(
            resourcesPath),
        m_scriptsLibraryPath(scriptsLibraryPath),
        m_engineVersion(engineVersion)
    {
        if (!m_bridge.load(bridgeLibraryPath))
        {
            qWarning() << "[OpenGLRenderer] No usable noi_engine preview bridge for engine version" << engineVersion
                << "- preview disabled for this project.";
            return;
        }

        if (const auto loadedVersion = m_bridge.engineVersion(); loadedVersion != engineVersion)
        {
            qWarning() << "[OpenGLRenderer] Preview bridge at" << bridgeLibraryPath << "reports engine version"
                << loadedVersion << "but the project declares" << engineVersion << "- the download may be corrupted.";
        }

        m_bridge.initGl(
            [](const char* name) -> void*
            {
                const auto* currentCtx = QOpenGLContext::currentContext();
                if (!currentCtx) return nullptr;

                return reinterpret_cast<void*>(currentCtx->getProcAddress(name));
            });

        this->m_gameHandle = m_bridge.create(gameWidth, gameHeight, this->m_resourcesPath);
    }

    OpenGLRenderer::~OpenGLRenderer()
    {
        if (m_gameHandle && m_bridge.isLoaded())
        {
            m_bridge.destroy(m_gameHandle);
        }
    }

    void OpenGLRenderer::render()
    {
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

    void OpenGLRenderer::synchronize(QQuickFramebufferObject* item)
    {
        const auto* view = static_cast<OpenGLView*>(item);
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
    }
}
