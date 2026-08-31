#pragma once

#include <QLibrary>
#include <QString>
#include <noi_engine/core/game.hpp>
#include <noi_engine/core/timer.hpp>
#include <noi_engine/core/components/camera_2d.hpp>

namespace noi_engine_editor
{
    class OpenglNoiEngineGame : public noi_engine::game
    {
        int m_game_width{};
        int m_game_height{};
        noi_engine::timer m_timer{};
        QLibrary m_scriptsLibrary{};

        [[nodiscard]] auto get_world() -> noi_engine::world&;
        [[nodiscard]] auto get_current_scene() const -> noi_engine::scene*;

        //TODO: handle 3d
        [[nodiscard]] auto get_camera_2d_component() -> noi_engine::camera_2d&;

    public:
        auto run() -> void;
        auto on_resize(int width, int height) -> void;
        auto set_scene_2d(std::unique_ptr<noi_engine::scene> scene) const -> void;

        auto load_scripts(const QString& scriptsLibraryPath) -> void;

        explicit OpenglNoiEngineGame(int game_width, int game_height, const QString& resourcesPath);
    };
}
