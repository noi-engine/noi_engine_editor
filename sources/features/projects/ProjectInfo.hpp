//
// Created by ricka on 8/10/26.
//

#pragma once

#include <QJsonObject>

namespace noi_engine_editor
{
    struct ProjectInfo
    {
        QString path;
        QString name;
        QString startScene;
        QString category{"2D"};
        QString version{"0.0.1"};
        QString scriptsLibrary;
        QString bridgeLibrary;
        QString engineVersion;

        int windowWidth{1280};
        int windowHeight{720};

        QDateTime lastOpened;

        [[nodiscard]] auto serialize() const -> QJsonObject;
        [[nodiscard]] static auto deserialize(const QJsonObject& object) -> ProjectInfo;

        auto operator==(const ProjectInfo &other) const -> bool = default;
    };
}
