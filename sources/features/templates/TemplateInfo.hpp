#pragma once

#include <QString>
#include <QJsonObject>

namespace noi_engine_editor
{
    struct TemplateInfo
    {
        QString id;
        QString name;
        QString author;
        QString version;
        QString description;
        QString repositoryUrl;

        bool operator==(const TemplateInfo& other) const = default;
        [[nodiscard]] static auto deserialize(const QJsonObject& json, const QString& repoUrl) -> TemplateInfo;
    };
}