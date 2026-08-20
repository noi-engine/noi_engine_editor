#include "OpenglNoiEngineGame.hpp"
#include <QDebug>
#include <noi_engine/core/resources/resource_loader.hpp>
#include <noi_engine/core/renderer/renderer.hpp>

auto noi_engine_editor::OpenglNoiEngineGame::run() -> void
{
    const float dt = m_timer.tick();

    this->update(dt);

    noi_engine::renderer::begin_frame();
    render();
    noi_engine::renderer::end_frame();
}

auto noi_engine_editor::OpenglNoiEngineGame::on_resize(const int width, const int height) const -> void
{
    this->m_scene_manager->on_resize(width, height);
}

noi_engine_editor::OpenglNoiEngineGame::OpenglNoiEngineGame(const QString& resourcesPath) : game(
    std::move(std::make_unique<noi_engine::source_resource_loader>(
        std::filesystem::path(resourcesPath.toStdString()))))
{
}
