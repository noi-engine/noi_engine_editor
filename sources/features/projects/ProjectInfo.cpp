//
// Created by ricka on 8/14/26.
//

#include "ProjectInfo.hpp"

auto noi_engine_editor::ProjectInfo::serialize() const -> QJsonObject
{
    QJsonObject obj;
    obj["name"] = name;
    obj["path"] = path;
    obj["version"] = version;
    obj["category"] = category;
    obj["start_scene"] = startScene;
    obj["lastOpened"] = lastOpened.toString(Qt::ISODate);

    QJsonObject windowObj;
    windowObj["width"] = windowWidth;
    windowObj["height"] = windowHeight;
    obj["window"] = windowObj;

    return obj;
}

auto noi_engine_editor::ProjectInfo::deserialize(const QJsonObject& object) -> ProjectInfo
{
    ProjectInfo info;
    info.name = object.value("name").toString();
    info.path = object.value("path").toString();
    info.version = object.value("version").toString("0.0.1");
    info.category = object.value("category").toString("2D");
    info.startScene = object.value("start_scene").toString();
    info.lastOpened = QDateTime::fromString(
        object.value("lastOpened").toString(),
        Qt::ISODate
    );

    if (object.contains("window") && object.value("window").isObject())
    {
        const QJsonObject windowObj = object.value("window").toObject();
        info.windowWidth = windowObj.value("width").toInt(1280);
        info.windowHeight = windowObj.value("height").toInt(720);
    }

    return info;
}