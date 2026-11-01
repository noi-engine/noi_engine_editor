#include "TemplateUrlResolver.hpp"
#include <QRegularExpression>

namespace
{
    struct GithubRepository
    {
        QString owner;
        QString name;
    };

    // Parses "https://github.com/<owner>/<repo>[.git][/]". Returns false if the URL doesn't match.
    auto parseGithubRepository(const QString& repositoryUrl, GithubRepository& out) -> bool
    {
        static const QRegularExpression regex(
            R"(^https://github\.com/([^/]+)/([^/]+?)(?:\.git)?/?$)"
        );

        const auto match = regex.match(repositoryUrl);
        if (!match.hasMatch())
        {
            return false;
        }

        out.owner = match.captured(1);
        out.name = match.captured(2);
        return true;
    }
}

auto noi_engine_editor::TemplateUrlResolver::templatesJsonUrl() -> QString
{
    return "https://gist.githubusercontent.com/RickaPrincy/e65848fd557eab6a0a4e19c96412ad68/raw/00a155e2beb1b45860ec1e80c405e816d8d74a27/noi_engine_templates.json";
}

auto noi_engine_editor::TemplateUrlResolver::templateJsonUrl(const QString& repositoryUrl) -> QString
{
    GithubRepository repository;
    if (!parseGithubRepository(repositoryUrl, repository))
    {
        return {};
    }

    return QString(
        "https://raw.githubusercontent.com/%1/%2/refs/heads/main/noi_engine.template.json"
    ).arg(repository.owner, repository.name);
}

auto noi_engine_editor::TemplateUrlResolver::zipUrl(const QString& repositoryUrl, const QString& branch) -> QString
{
    GithubRepository repository;
    if (!parseGithubRepository(repositoryUrl, repository))
    {
        return {};
    }

    return QString(
        "https://github.com/%1/%2/archive/refs/heads/%3.zip"
    ).arg(repository.owner, repository.name, branch);
}
