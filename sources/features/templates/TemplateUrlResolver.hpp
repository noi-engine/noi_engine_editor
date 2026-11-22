#pragma once

#include <QString>

namespace noi_engine_editor::TemplateUrlResolver
{
    [[nodiscard]] auto templatesJsonUrl() -> QString;
    [[nodiscard]] auto templateJsonUrl(const QString& repositoryUrl) -> QString;
    [[nodiscard]] auto zipUrl(const QString& repositoryUrl, const QString& branch = "main") -> QString;
    // The archive of the tag a template version was released under ("0.0.1064" -> tag "v0.0.1064"),
    // so that installing an older version doesn't download whatever the main branch is today.
    [[nodiscard]] auto zipUrlForVersion(const QString& repositoryUrl, const QString& version) -> QString;
}