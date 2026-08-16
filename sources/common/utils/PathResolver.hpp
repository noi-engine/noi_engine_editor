//
// Created by ricka on 8/14/26.
//

#pragma once

#include <QString>

namespace noi_engine_editor::PathResolver
{
    auto init() -> void;
    [[nodiscard]] auto confPath() -> QString;
    [[nodiscard]] auto recentProjectsPath() -> QString;
    [[nodiscard]] auto templateEnginePath() -> QString;

    [[nodiscard]] auto templatesPath() -> QString;
    [[nodiscard]] auto templateFilePath(const QString& templatePath) -> QString;
    [[nodiscard]] auto templateAbsolutePath(const QString& templateId) -> QString;

    [[nodiscard]] auto fallBackDefaultProjectsPath() -> QString;
    [[nodiscard]] auto projectFilePath(const QString& projectPath) -> QString;
    [[nodiscard]] auto projectResourcesPath(const QString& projectPath) -> QString;
}
