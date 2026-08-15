#include "RecentProjectsModel.hpp"

namespace noi_engine_editor
{
    RecentProjectsModel::RecentProjectsModel(QObject* parent)
        : QAbstractListModel(parent)
    {
    }

    auto RecentProjectsModel::manager() const -> RecentProjectsManager*
    {
        return m_manager;
    }

    auto RecentProjectsModel::setManager(RecentProjectsManager* manager) -> void
    {
        if (m_manager == manager)
        {
            return;
        }

        if (m_manager)
        {
            disconnect(m_manager, &RecentProjectsManager::projectsChanged, this, &RecentProjectsModel::refreshModel);
        }

        m_manager = manager;

        if (m_manager)
        {
            connect(m_manager, &RecentProjectsManager::projectsChanged, this, &RecentProjectsModel::refreshModel);
        }

        emit managerChanged();
        refreshModel();
    }

    auto RecentProjectsModel::refreshModel() -> void
    {
        beginResetModel();
        m_cachedProjects = m_manager ? m_manager->projects() : QList<ProjectInfo>{};
        endResetModel();
    }

    auto RecentProjectsModel::rowCount(const QModelIndex& parent) const -> int
    {
        if (parent.isValid()) return 0;
        return static_cast<int>(m_cachedProjects.size());
    }

    auto RecentProjectsModel::data(const QModelIndex& index, int role) const -> QVariant
    {
        if (!index.isValid() || index.row() >= m_cachedProjects.size())
        {
            return {};
        }

        const auto& project = m_cachedProjects[index.row()];

        switch (role)
        {
        case NameRole: return project.name;
        case PathRole: return project.path;
        case LastOpenedRole: return project.lastOpened;
        default: return {};
        }
    }

    auto RecentProjectsModel::roleNames() const -> QHash<int, QByteArray>
    {
        return {
            {NameRole, "name"},
            {PathRole, "path"},
            {LastOpenedRole, "lastOpened"}
        };
    }
}