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
    createDirOrThrow(toolsPath());
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

auto noi_engine_editor::PathResolver::toolsPath() -> QString
{
    return confPath() + "/tools";
}

auto noi_engine_editor::PathResolver::noiEngineRootPath() -> QString
{
    return toolsPath() + "/noi_engine";
}

auto noi_engine_editor::PathResolver::noiEnginePath(const QString& version) -> QString
{
    return QDir(noiEngineRootPath()).filePath(version);
}

auto noi_engine_editor::PathResolver::noiEngineContentPath(const QString& version) -> QString
{
    return noiEnginePath(version) + "/noi_engine";
}

auto noi_engine_editor::PathResolver::resourceCompilerRootPath() -> QString
{
    return toolsPath() + "/resources_compiler";
}

auto noi_engine_editor::PathResolver::resourceCompilerPath(const QString& version) -> QString
{
    return QDir(resourceCompilerRootPath()).filePath(version);
}

auto noi_engine_editor::PathResolver::resourceCompilerContentPath(const QString& version) -> QString
{
    return resourceCompilerPath(version) + "/resources_compiler";
}

auto noi_engine_editor::PathResolver::fallBackDefaultProjectsPath() -> QString
{
    return QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/noi_engine/projects";
}

auto noi_engine_editor::PathResolver::projectFilePath(const QString& projectPath) -> QString
{
    return projectPath + "/noi_engine.proj.json";
}

auto noi_engine_editor::PathResolver::projectResourcesPath(const QString& projectPath) -> QString
{
    return projectPath + "/resources";
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
