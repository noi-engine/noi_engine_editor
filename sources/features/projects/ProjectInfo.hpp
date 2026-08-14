//
// Created by ricka on 8/10/26.
//

#pragma once

#include <QJsonObject>

namespace noi_engine_editor
{
    struct ProjectInfo
    {
        QString name;
        QString path;
        QDateTime lastOpened;

        bool operator==(const ProjectInfo& other) const = default;

        [[nodiscard]] auto serialize() const -> QJsonObject;
        [[nodiscard]] static auto deserialize(const QJsonObject& object) -> ProjectInfo;
    };
}
