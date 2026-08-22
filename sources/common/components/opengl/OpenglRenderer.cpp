#include "OpenglView.hpp"
#include "OpenglRenderer.hpp"
#include <noi_engine/core/game.hpp>
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

    OpenGLRenderer::OpenGLRenderer(const QString& resourcesPath) : m_resourcesPath(
        resourcesPath)
    {
        noi_engine::game::init(
            [](const char* name) -> void*
            {
                const auto* currentCtx = QOpenGLContext::currentContext();
                if (!currentCtx) return nullptr;

                return reinterpret_cast<void*>(currentCtx->getProcAddress(name));
            });

        this->m_game = std::make_unique<OpenglNoiEngineGame>(this->m_resourcesPath);
    }

    void OpenGLRenderer::render()
    {
        if (this->m_game)
        {
            if (auto* f = QOpenGLContext::currentContext()->functions())
            {
                f->glViewport(0, 0, this->m_width, this->m_height);
            }

            this->m_game->run();
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

        if (this->m_game)
        {
            if (this->m_width != realWidth || this->m_height != realHeight)
            {
                this->m_width = realWidth;
                this->m_height = realHeight;
                this->m_game->on_resize(m_width, m_height);
            }
        }

        if (const auto newPath = view->scenePath(); m_currentPath != newPath)
        {
            m_currentPath = newPath;
            if (!m_currentPath.isEmpty())
            {
                auto& resources = this->m_game->resources();
                const auto relativeScenePath = getSceneResourceDotPath(this->m_resourcesPath, this->m_currentPath);
                this->m_game->set_scene(std::move(resources.load_scene(relativeScenePath.toStdString())));
                this->m_game->on_resize(m_width, m_height);
            }
        }
    }
}
