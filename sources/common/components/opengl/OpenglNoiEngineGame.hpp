#pragma once

#include <QString>
#include <noi_engine/core/game.hpp>
#include <noi_engine/core/timer.hpp>

namespace noi_engine_editor
{
    class OpenglNoiEngineGame: public noi_engine::game
    {
        noi_engine::timer m_timer{};

    public:
        auto run() -> void;
        auto on_resize(int width, int height) const -> void;

        explicit OpenglNoiEngineGame(const QString& resourcesPath);
    };
}