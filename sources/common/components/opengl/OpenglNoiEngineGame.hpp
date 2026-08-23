#pragma once

#include <QString>
#include <noi_engine/core/game.hpp>
#include <noi_engine/core/timer.hpp>
#include <noi_engine/core/components/camera_2d.hpp>

namespace noi_engine_editor
{
    class OpenglNoiEngineGame : public noi_engine::game
    {
        noi_engine::timer m_timer{};

        [[nodiscard]] auto get_world() -> noi_engine::world&;
        [[nodiscard]] auto get_current_scene() const -> noi_engine::scene*;

        //TODO: handle 3d
        [[nodiscard]] auto get_camera_2d_component() -> noi_engine::camera_2d&;

    public:
        auto run() -> void;
        auto on_resize(int width, int height) -> void;

        explicit OpenglNoiEngineGame(const QString& resourcesPath);
    };
}
