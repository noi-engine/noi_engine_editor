#include "OpenglNoiEngineGame.hpp"
#include <QDebug>
#include <QFileInfo>
#include <noi_engine/core/resources/resource_loader.hpp>
#include <noi_engine/core/components/camera_2d.hpp>
#include <noi_engine/core/components/dirty.hpp>
#include <noi_engine/core/components/transform.hpp>
#include <noi_engine/core/renderer/renderer.hpp>

constexpr float PIXELS_PER_UNIT = 100.0f;

namespace
{
    using register_scripts_fn = void (*)(noi_engine::game&);
    constexpr auto REGISTER_SCRIPTS_SYMBOL = "noi_engine_register_scripts";
}

auto noi_engine_editor::OpenglNoiEngineGame::load_scripts(const QString& scriptsLibraryPath) -> void
{
    if (m_scriptsLibrary.isLoaded())
    {
        return;
    }

    if (!QFileInfo::exists(scriptsLibraryPath))
    {
        qWarning() << "Game scripts library not found (build the project first):" << scriptsLibraryPath;
        return;
    }

    m_scriptsLibrary.setFileName(scriptsLibraryPath);

    if (!m_scriptsLibrary.load())
    {
        qWarning() << "Failed to load game scripts library" << scriptsLibraryPath << ":" <<
            m_scriptsLibrary.errorString();
        return;
    }

    const auto register_scripts = reinterpret_cast<register_scripts_fn>(
        m_scriptsLibrary.resolve(REGISTER_SCRIPTS_SYMBOL));

    if (!register_scripts)
    {
        qWarning() << "Game scripts library" << scriptsLibraryPath << "has no" << REGISTER_SCRIPTS_SYMBOL <<
            "entry point";
        return;
    }

    register_scripts(*this);
}

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

auto noi_engine_editor::OpenglNoiEngineGame::set_scene_2d(std::unique_ptr<noi_engine::scene> scene) const -> void
{
    this->set_scene(std::move(scene));
    auto& resources_ref = this->resources();

    auto material = std::make_unique<noi_engine::material>();;
    material->set_color("u_color", glm::vec4{1, 0, 0, 1});
    material->set_shader(resources_ref.get_handle<noi_engine::shader>("color_shader"));
    const auto material_handle = resources_ref.load_instance(std::move(material));
    const auto mesh_handle = resources_ref.get_handle<noi_engine::mesh>("quad_2d");

    const auto camera_entity = this->get_current_scene()->get_camera_entity();
    auto& world = this->get_current_scene()->get_world();

    world.add<noi_engine::mesh_renderer>(camera_entity, {
                                             .m_mesh = mesh_handle,
                                             .m_material = material_handle
                                         });

    auto& transform = world.get<noi_engine::transform>(camera_entity);
    const float world_width = static_cast<float>(this->m_game_width) / PIXELS_PER_UNIT;
    const float world_height = static_cast<float>(this->m_game_height) / PIXELS_PER_UNIT;
    transform.scale = glm::vec3{world_width, world_height, 1.0};

    world.add<noi_engine::dirty<noi_engine::transform>>(camera_entity, noi_engine::dirty<noi_engine::transform>{});
}

noi_engine_editor::OpenglNoiEngineGame::OpenglNoiEngineGame(const int game_width, const int game_height,
                                                            const QString& resourcesPath) : game(
        std::move(std::make_unique<noi_engine::source_resource_loader>(
            std::filesystem::path(resourcesPath.toStdString())))),
    m_game_width(game_width), m_game_height(game_height)
{
}
