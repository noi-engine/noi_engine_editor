#include "LocalTemplateManager.hpp"
#include "PathResolver.hpp"
#include "TemplateInfo.hpp"
#include "Version.hpp"

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
        versions.removeIf([](const QString& version) { return version.endsWith(QStringLiteral(".part")); });
        std::sort(versions.begin(), versions.end(), [](const QString& lhs, const QString& rhs) {
            return Version::compare(lhs, rhs) > 0;
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
                if (!found || Version::compare(info.version, latest.version) > 0)
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
