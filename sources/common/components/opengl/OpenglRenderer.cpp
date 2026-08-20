#include "OpenglView.hpp"
#include "OpenglRenderer.hpp"
#include <noi_engine/core/game.hpp>
#include <QOpenGLFramebufferObject>
#include <QOpenGLFunctions>

namespace noi_engine_editor
{
    OpenGLRenderer::OpenGLRenderer()
    {
        noi_engine::game::init(
            [](const char* name) -> void*
            {
                const auto* currentCtx = QOpenGLContext::currentContext();
                if (!currentCtx) return nullptr;

                return reinterpret_cast<void*>(currentCtx->getProcAddress(name));
            });

        this->m_game = std::make_unique<OpenglNoiEngineGame>();
    }

    void OpenGLRenderer::render()
    {
        if (auto* f = QOpenGLContext::currentContext()->functions())
        {
            f->glViewport(0, 0, m_width, m_height);
        }

        if (this->m_game)
        {
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
        const int width = static_cast<int>(view->width());
        const int height = static_cast<int>(view->height());

        if (const auto newPath = view->scenePath(); m_currentPath != newPath)
        {
            m_currentPath = newPath;

            if (this->m_game && width != m_width && height != m_height)
            {
                this->m_width = width;
                this->m_height = height;
                this->m_game->on_resize(this->m_width, this->m_height);
            }

            if (!m_currentPath.isEmpty())
            {
                auto& resources = this->m_game->resources();
                this->m_game->set_scene(std::move(resources.load_scene("resources/scenes/main.scene")));
            }
        }
    }
}
