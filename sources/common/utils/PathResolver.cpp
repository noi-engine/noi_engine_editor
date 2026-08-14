//
// Created by ricka on 8/14/26.
//

#include "PathResolver.hpp"

#include <QDir>
#include <QStandardPaths>

static auto createDirOrThrow(const QString& path) -> void;

auto noi_engine_editor::PathResolver::init() -> void
{
    createDirOrThrow(confPath());
    createDirOrThrow(templatesPath());
    createDirOrThrow(fallBackDefaultProjectsPath());
}

auto noi_engine_editor::PathResolver::confPath() -> QString
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
}

auto noi_engine_editor::PathResolver::recentProjectsPath() -> QString
{
    return confPath() + "/recent_projects.json";
}

auto noi_engine_editor::PathResolver::fallBackDefaultProjectsPath() -> QString
{
    return QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/noi_engine/projects";
}

auto noi_engine_editor::PathResolver::projectFilePath(const QString& projectPath) -> QString
{
    return projectPath + "/noi_engine.proj.json";
}

auto noi_engine_editor::PathResolver::templateFilePath(const QString& templatePath) -> QString
{
    return templatePath + "/noi_engine.template.json";
}

auto noi_engine_editor::PathResolver::templateAbsolutePath(const QString& templateId) -> QString
{
    return QDir(templatesPath()).filePath(templateId);
}

auto createDirOrThrow(const QString& path) -> void
{
    if (!QDir().mkpath(path))
    {
        throw std::runtime_error(("Cannot create " + path).toStdString());
    }
}

auto noi_engine_editor::PathResolver::templatesPath() -> QString
{
    return confPath() + "/templates";
}
