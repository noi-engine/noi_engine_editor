#include "OpenglNoiEngineGame.hpp"
#include <QDebug>
#include <noi_engine/core/resources/resource_loader.hpp>
#include <noi_engine/core/components/camera_2d.hpp>
#include <noi_engine/core/renderer/renderer.hpp>

constexpr float PIXELS_PER_UNIT = 100.0f;

auto noi_engine_editor::OpenglNoiEngineGame::get_world() -> noi_engine::world&
{
    const auto current_scene = this->get_current_scene();

    assert(current_scene);

    return current_scene->get_world();
}

auto noi_engine_editor::OpenglNoiEngineGame::get_current_scene() const -> noi_engine::scene*
{
    return this->m_scene_manager->current();
}

auto noi_engine_editor::OpenglNoiEngineGame::get_camera_2d_component() -> noi_engine::camera_2d&
{
    const auto camera_entity = this->get_current_scene()->get_camera_entity();
    auto& world = this->get_world();
    assert(world.has<noi_engine::camera_2d>(camera_entity));

    return world.get<noi_engine::camera_2d>(camera_entity);
}

auto noi_engine_editor::OpenglNoiEngineGame::run() -> void
{
    const float dt = m_timer.tick();

    this->update(dt);

    noi_engine::renderer::begin_frame();
    render();
    noi_engine::renderer::end_frame();
}

auto noi_engine_editor::OpenglNoiEngineGame::on_resize(const int width, const int height) -> void
{
    if (!this->get_current_scene())
    {
        return;
    }

    auto& cam = this->get_camera_2d_component();
    cam.orthographic_size = (static_cast<float>(height) / PIXELS_PER_UNIT) * 0.5f;
    cam.aspect_ratio = static_cast<float>(width) / static_cast<float>(height);

    this->m_scene_manager->on_resize(width, height);
}

noi_engine_editor::OpenglNoiEngineGame::OpenglNoiEngineGame(const QString& resourcesPath) : game(
    std::move(std::make_unique<noi_engine::source_resource_loader>(
        std::filesystem::path(resourcesPath.toStdString()))))
{
}
