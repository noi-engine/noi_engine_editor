#include "TemplateUrlResolver.hpp"
#include <QRegularExpression>

auto noi_engine_editor::TemplateUrlResolver::templatesJsonUrl() -> QString
{
    return "https://gist.githubusercontent.com/RickaPrincy/e65848fd557eab6a0a4e19c96412ad68/raw/00a155e2beb1b45860ec1e80c405e816d8d74a27/noi_engine_templates.json";
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

auto noi_engine_editor::TemplateUrlResolver::zipUrl(const QString& repositoryUrl, const QString& branch) -> QString
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
        "https://github.com/%1/%2/archive/refs/heads/%3.zip"
    ).arg(owner, repository, branch);
}
