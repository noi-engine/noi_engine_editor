//
// Created by ricka on 8/14/26.
//

#include "ProjectInfo.hpp"

auto noi_engine_editor::ProjectInfo::serialize() const -> QJsonObject
{
    QJsonObject obj;
    obj["name"] = name;
    obj["path"] = path;
    obj["lastOpened"] = lastOpened.toString(Qt::ISODate);
    return obj;
}

auto noi_engine_editor::ProjectInfo::deserialize(const QJsonObject& object) -> ProjectInfo
{
    return {
        .name = object["name"].toString(),
        .path = object["path"].toString(),
        .lastOpened = QDateTime::fromString(
            object["lastOpened"].toString(),
            Qt::ISODate
        )
    };
}
