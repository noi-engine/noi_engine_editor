#include "LocalTemplateManager.hpp"
#include "PathResolver.hpp"
#include "TemplateInfo.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QTemporaryFile>
#include <QDebug>
#include "TemplateInstaller.hpp"

#include <algorithm>

namespace
{
    // Compares dot-separated, numeric version strings (e.g. "0.0.9" vs "0.0.10").
    // Falls back to plain string comparison for any non-numeric segment.
    auto compareVersions(const QString& lhs, const QString& rhs) -> int
    {
        const auto lhsParts = lhs.split('.');
        const auto rhsParts = rhs.split('.');
        const auto count = std::max(lhsParts.size(), rhsParts.size());

        for (int i = 0; i < count; ++i)
        {
            const auto lhsPart = i < lhsParts.size() ? lhsParts[i] : QString("0");
            const auto rhsPart = i < rhsParts.size() ? rhsParts[i] : QString("0");

            bool lhsIsNumber = false;
            bool rhsIsNumber = false;
            const auto lhsNumber = lhsPart.toLongLong(&lhsIsNumber);
            const auto rhsNumber = rhsPart.toLongLong(&rhsIsNumber);

            if (lhsIsNumber && rhsIsNumber)
            {
                if (lhsNumber != rhsNumber)
                {
                    return lhsNumber < rhsNumber ? -1 : 1;
                }
            }
            else if (const auto cmp = lhsPart.compare(rhsPart); cmp != 0)
            {
                return cmp < 0 ? -1 : 1;
            }
        }

        return 0;
    }
}

namespace noi_engine_editor
{
    LocalTemplateManager::LocalTemplateManager(QObject* parent)
        : QObject(parent)
    {
        loadLocalTemplates();
    }

    auto LocalTemplateManager::templates() const -> QVariantList
    {
        return m_templates;
    }

    auto LocalTemplateManager::isDownloading() const -> bool
    {
        return m_isDownloading;
    }

    auto LocalTemplateManager::downloadingTemplateId() const -> QString
    {
        return m_downloadingTemplateId;
    }

    auto LocalTemplateManager::installedVersions(const QString& templateId) const -> QVariantList
    {
        const QDir templateRootDir(PathResolver::templateRootPath(templateId));

        auto versions = templateRootDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        std::sort(versions.begin(), versions.end(), [](const QString& lhs, const QString& rhs) {
            return compareVersions(lhs, rhs) > 0;
        });

        QVariantList result;
        for (const auto& version : versions)
        {
            result.append(version);
        }
        return result;
    }

    auto LocalTemplateManager::latestInstalledVersion(const QString& templateId) const -> QString
    {
        const auto versions = installedVersions(templateId);
        return versions.isEmpty() ? QString() : versions.first().toString();
    }

    auto LocalTemplateManager::downloadTemplate(const QString& templateId, const QString& version, const QString& repositoryUrl) -> void
    {
        if (m_isDownloading)
        {
            return;
        }

        m_isDownloading = true;
        m_downloadingTemplateId = templateId;
        emit isDownloadingChanged();

        auto installer = std::make_shared<TemplateInstaller>(m_networkManager);
        installer->install(
            templateId,
            version,
            repositoryUrl,
            [this, templateId, installer](const bool success)
            {
                m_isDownloading = false;
                m_downloadingTemplateId.clear();
                emit isDownloadingChanged();

                if (success)
                {
                    loadLocalTemplates();
                }
                else
                {
                    qWarning() << "[LocalTemplateManager] Template processing failed for ID:" << templateId;
                }

                emit downloadFinished(templateId, success);
            }
        );
    }

    auto LocalTemplateManager::removeTemplateVersion(const QString& templateId, const QString& version) -> void
    {
        QDir(PathResolver::templateAbsolutePath(templateId, version)).removeRecursively();

        if (QDir templateRootDir(PathResolver::templateRootPath(templateId));
            templateRootDir.exists() && templateRootDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot).isEmpty())
        {
            templateRootDir.removeRecursively();
        }

        loadLocalTemplates();
    }

    auto LocalTemplateManager::loadLocalTemplates() -> void
    {
        m_templates.clear();

        const auto rootTemplatesPath = PathResolver::templatesPath();
        const QDir templatesDir(rootTemplatesPath);
        if (!templatesDir.exists())
        {
            emit templatesChanged();
            return;
        }

        const auto templateIds = templatesDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);

        for (const auto& templateId : templateIds)
        {
            const QDir templateRootDir(templatesDir.absoluteFilePath(templateId));
            const auto versions = templateRootDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);

            bool found = false;
            TemplateInfo latest;

            for (const auto& version : versions)
            {
                const auto versionDirPath = templateRootDir.absoluteFilePath(version);
                const auto jsonPath = PathResolver::templateFilePath(versionDirPath);

                QFile file(jsonPath);
                if (!file.open(QIODevice::ReadOnly))
                {
                    continue;
                }

                const auto fileData = file.readAll();
                file.close();

                QJsonParseError parseError;
                const auto doc = QJsonDocument::fromJson(fileData, &parseError);
                if (parseError.error != QJsonParseError::NoError || !doc.isObject())
                {
                    continue;
                }

                const auto info = TemplateInfo::deserialize(doc.object(), "");
                if (!found || compareVersions(info.version, latest.version) > 0)
                {
                    latest = info;
                    found = true;
                }
            }

            if (!found)
            {
                continue;
            }

            QVariantMap tMap;
            tMap["id"] = latest.id;
            tMap["name"] = latest.name;
            tMap["author"] = latest.author;
            tMap["version"] = latest.version;
            tMap["description"] = latest.description;
            tMap["engineVersion"] = latest.engineVersion;
            tMap["resourceCompilerVersion"] = latest.resourceCompilerVersion;
            tMap["editorBridgeVersion"] = latest.editorBridgeVersion;

            m_templates.append(tMap);
        }

        emit templatesChanged();
    }
}
