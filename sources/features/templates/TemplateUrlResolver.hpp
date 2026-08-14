#pragma once

#include <QString>

namespace noi_engine_editor::TemplateUrlResolver
{
    [[nodiscard]] auto templatesJsonUrl() -> QString;
    [[nodiscard]] auto templateJsonUrl(const QString& repositoryUrl) -> QString;
}