#include "TemplateInfo.hpp"

auto noi_engine_editor::TemplateInfo::deserialize(const QJsonObject &json, const QString &repoUrl) -> noi_engine_editor::TemplateInfo
{
    return TemplateInfo{
    .id = json["id"].toString(),
    .name = json["name"].toString(),
    .author = json["author"].toString(),
    .version = json["version"].toString(),
    .description = json["description"].toString(),
    .repositoryUrl = repoUrl,
    .engineVersion = json["noi_engine_version"].toString(),
    .resourceCompilerVersion = json["resources_compiler_version"].toString(),
    .editorBridgeVersion = json["editor_bridge_version"].toString()
    };
}
