#include "RecentProjectsManager.hpp"

#include <QDebug>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonObject>
#include <QStandardPaths>

#include "../../common/utils/JsonIO.hpp"
#include "../../common/utils/PathResolver.hpp"
#include "../../common/utils/JsonSerializer.hpp"

namespace noi_engine_editor
{
    static constexpr int MAX_RECENT_PROJECTS = 15;

    RecentProjectsManager::RecentProjectsManager(QObject* parent) : QObject(parent)
    {
        loadFromDisk();
    }

    auto RecentProjectsManager::addProject(const QString& name, const QString& path) -> void
    {
        const auto cleanPath = QFileInfo(path).absoluteFilePath();
        m_projects.removeIf([&cleanPath](const ProjectInfo& proj)
            -> bool
            {
                return proj.path == cleanPath;
            });

        m_projects.prepend(ProjectInfo{
            .path = cleanPath,
            .name = name,
            .lastOpened = QDateTime::currentDateTime()
        });

        if (m_projects.size() > MAX_RECENT_PROJECTS)
        {
            m_projects.removeLast();
        }

        saveToDisk();
        emit projectsChanged();
    }

    auto RecentProjectsManager::projects() const -> QList<ProjectInfo>
    {
        return this->m_projects;
    }

    auto RecentProjectsManager::removeProject(const QString& path) -> void
    {
        const auto cleanPath = QFileInfo(path).absoluteFilePath();
        const auto removed = m_projects.removeIf([&cleanPath](const ProjectInfo& proj)
            -> bool
            {
                return proj.path == cleanPath;
            });

        if (removed > 0)
        {
            saveToDisk();
            emit projectsChanged();
        }
    }

    auto RecentProjectsManager::clearMissingProjects() -> void
    {
        const auto removed = m_projects.removeIf([](const ProjectInfo& proj)
            -> bool
            {
                return !QFileInfo::exists(proj.path);
            });

        if (removed > 0)
        {
            saveToDisk();
            emit projectsChanged();
        }
    }

    auto RecentProjectsManager::saveToDisk() -> void
    {
        QJsonArray array;
        for (const auto& project : m_projects)
        {
            array.append(Json::serialize<ProjectInfo>(project));
        }
        try
        {
            JsonIO::write(PathResolver::recentProjectsPath(), QJsonDocument(array));
        }
        catch (const std::exception& e)
        {
            qWarning() << "[RecentProjectsManager] Failed to save recent projects:" << e.what();
        }
    }

    auto RecentProjectsManager::loadFromDisk() -> void
    {
        m_projects.clear();
        QJsonDocument doc;

        try
        {
            doc = JsonIO::read(PathResolver::recentProjectsPath());
        }
        catch ([[maybe_unused]] std::runtime_error& e)
        {
            doc = QJsonDocument(QJsonArray());
        }

        for (const auto array = doc.array(); const auto& value : array)
        {
            if (const auto project = Json::deserialize<ProjectInfo>(value.toObject()); !project.path.isEmpty())
            {
                m_projects.append(project);
            }
        }
        emit projectsChanged();
    }
}
