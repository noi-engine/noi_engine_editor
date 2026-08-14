#include "CurrentProjectManager.hpp"

#include <QJsonObject>

#include "../../common/utils/JsonIO.hpp"
#include "../../common/utils/PathResolver.hpp"

namespace noi_engine_editor
{
    CurrentProjectManager::CurrentProjectManager(QObject* parent) : QObject(parent)
    {
    }

    auto CurrentProjectManager::openProject(const QString& path) -> bool
    {
        const auto doc = JsonIO::read(PathResolver::projectFilePath(path));

        if (!doc.isObject())
        {
            emit projectOpenFailed(tr("Invalid project file"));
            return false;
        }

        m_name = doc.object()["name"].toString();
        m_path = path;
        m_isOpen = true;

        emit projectChanged();
        return true;
    }

    auto CurrentProjectManager::closeProject() -> void
    {
        m_name.clear();
        m_path.clear();
        m_isOpen = false;

        emit projectChanged();
    }

    auto CurrentProjectManager::name() const -> QString
    {
        return m_name;
    }

    auto CurrentProjectManager::path() const -> QString
    {
        return m_path;
    }

    auto CurrentProjectManager::isOpen() const -> bool
    {
        return m_isOpen;
    }
}
