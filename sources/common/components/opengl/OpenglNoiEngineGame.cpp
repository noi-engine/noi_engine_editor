#include "OpenglNoiEngineGame.hpp"
#include <QDebug>
#include <noi_engine/core/resources/resource_loader.hpp>
#include <noi_engine/core/components/camera_2d.hpp>
#include <noi_engine/core/renderer/renderer.hpp>

constexpr float PIXELS_PER_UNIT = 100.0f;

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
    const auto current_scene = this->m_scene_manager->current();
    if (!current_scene)
    {
        return;
    }

    auto& world = current_scene->get_world();
    if (!world.has<noi_engine::camera_2d>(current_scene->get_camera_entity()))
    {
        //TODO: camera_3d: same trick (probably)
        return;
    }

    qDebug() << "Size: width=" << width << " & height= " << height << "\n";
    auto& cam = world.get<noi_engine::camera_2d>(current_scene->get_camera_entity());
    cam.orthographic_size = (static_cast<float>(height) / PIXELS_PER_UNIT) * 0.5f;
    cam.aspect_ratio = static_cast<float>(width) / static_cast<float>(height);

    this->m_scene_manager->on_resize(width, height);
}

noi_engine_editor::OpenglNoiEngineGame::OpenglNoiEngineGame(const QString& resourcesPath) : game(
    std::move(std::make_unique<noi_engine::source_resource_loader>(
        std::filesystem::path(resourcesPath.toStdString()))))
{
}
