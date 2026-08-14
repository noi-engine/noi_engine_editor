#include "LocalTemplateManager.hpp"
#include "PathResolver.hpp"
#include "TemplateInfo.hpp"

#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>

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

    auto LocalTemplateManager::loadLocalTemplates() -> void
    {
        m_templates.clear();

        const QDir templatesDir(PathResolver::templatesPath());
        if (!templatesDir.exists())
        {
            emit templatesChanged();
            return;
        }

        const QStringList subDirs = templatesDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QString& subDir : subDirs)
        {
            const QString jsonPath = PathResolver::templateFilePath(templatesDir.absoluteFilePath(subDir));

            QFile file(jsonPath);
            if (!file.open(QIODevice::ReadOnly))
            {
                continue;
            }

            const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
            file.close();

            if (!doc.isObject())
            {
                continue;
            }
            const TemplateInfo info = TemplateInfo::deserialize(doc.object(), "");

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