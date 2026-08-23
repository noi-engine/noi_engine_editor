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

    auto LocalTemplateManager::isInstalled(const QString& templateId) const -> bool
    {
        for (const auto& item : m_templates)
        {
            if (item.toMap().value("id").toString() == templateId)
            {
                return true;
            }
        }
        return false;
    }

    auto LocalTemplateManager::downloadTemplate(const QString& templateId, const QString& repositoryUrl) -> void
    {
        if (m_isDownloading)
        {
            return;
        }

        m_isDownloading = true;
        emit isDownloadingChanged();

        auto installer = std::make_shared<TemplateInstaller>(m_networkManager);
        installer->install(templateId, repositoryUrl, [this, templateId, installer](const bool success)
        {
            m_isDownloading = false;
            emit isDownloadingChanged();

            if (success)
            {
                loadLocalTemplates();
            }
            else
            {
                qWarning() << "Template processing failed for ID:" << templateId;
            }

            emit downloadFinished(templateId, success);
        });
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

        const auto subDirs = templatesDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);

        for (const auto& subDir : subDirs)
        {
            const auto subDirPath = templatesDir.absoluteFilePath(subDir);
            const auto jsonPath = PathResolver::templateFilePath(subDirPath);

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
            QVariantMap tMap;
            tMap["id"] = info.id;
            tMap["name"] = info.name;
            tMap["author"] = info.author;
            tMap["version"] = info.version;
            tMap["description"] = info.description;

            m_templates.append(tMap);
        }

        emit templatesChanged();
    }
}
