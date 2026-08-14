#include "TemplateUrlResolver.hpp"
#include <QRegularExpression>

auto noi_engine_editor::TemplateUrlResolver::templatesJsonUrl() -> QString
{
    return "https://raw.githubusercontent.com/noi-engine/templates/refs/heads/"
           "main/templates.json";
}

auto noi_engine_editor::TemplateUrlResolver::templateJsonUrl(const QString& repositoryUrl) -> QString
{
    static const QRegularExpression regex(
        R"(^https://github\.com/([^/]+)/([^/]+?)(?:\.git)?/?$)"
    );

    const auto match = regex.match(repositoryUrl);

    if (!match.hasMatch())
    {
        return {};
    }

    const auto owner = match.captured(1);
    const auto repository = match.captured(2);

    return QString(
        "https://raw.githubusercontent.com/%1/%2/refs/heads/main/noi_engine.template.json"
    ).arg(owner, repository);
}