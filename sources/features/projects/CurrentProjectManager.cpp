#include "CurrentProjectManager.hpp"

#include <QJsonObject>

#include "../../common/utils/JsonSerializer.hpp"
#include "../../common/utils/JsonIO.hpp"
#include "../../common/utils/PathResolver.hpp"

namespace noi_engine_editor
{
    CurrentProjectManager::CurrentProjectManager(QObject* parent) : QObject(parent)
    {
    }

    auto CurrentProjectManager::openProject(const QString& path) -> bool
    {
        try
        {
            const auto doc = JsonIO::read(PathResolver::projectFilePath(path));
            if (!doc.isObject())
            {
                emit projectOpenFailed(tr("Invalid project file"));
                return false;
            }

            m_project = Json::deserialize<ProjectInfo>(doc.object());
        }
        catch (const std::runtime_error &e)
        {
            qDebug()  << e.what();
            emit projectOpenFailed(tr("Invalid project file"));
            return false;
        }


        m_path = path;
        m_isOpen = true;

        emit projectChanged();
        emit nameChanged();
        emit versionChanged();
        emit categoryChanged();
        emit startSceneChanged();
        emit windowWidthChanged();
        emit windowHeightChanged();
        return true;
    }


    auto CurrentProjectManager::saveProject() const -> bool
    {
        if (!m_isOpen || m_path.isEmpty())
        {
            return false;
        }

        try
        {
            const QJsonObject json = Json::serialize(m_project);
            JsonIO::write(PathResolver::projectFilePath(m_path), QJsonDocument(json));
            return true;
        }
        catch (const std::exception& e)
        {
            qDebug() << "Failed to save project:" << e.what(); //TODO
            return false;
        }
    }

    auto CurrentProjectManager::closeProject() -> void
    {
        m_path.clear();
        m_isOpen = false;
        m_project = ProjectInfo{};

        emit projectChanged();
    }

    auto CurrentProjectManager::name() const -> QString
    {
        return m_project.name;
    }

    auto CurrentProjectManager::version() const -> QString
    {
        return m_project.version;
    }

    auto CurrentProjectManager::category() const -> QString
    {
        return m_project.category;
    }

    auto CurrentProjectManager::startScene() const -> QString
    {
        return m_project.startScene;
    }

    auto CurrentProjectManager::windowWidth() const -> int
    {
        return m_project.windowWidth;
    }

    auto CurrentProjectManager::windowHeight() const -> int
    {
        return m_project.windowHeight;
    }

    auto CurrentProjectManager::setWindowWidth(const int width) -> void
    {
        this->m_project.windowWidth = width;
    }

    auto CurrentProjectManager::setWindowHeight(const int height) -> void
    {
        this->m_project.windowHeight = height;
    }

    auto CurrentProjectManager::setName(const QString& name) -> void
    {
        this->m_project.name = name;
    }

    auto CurrentProjectManager::setVersion(const QString& version) -> void
    {
        this->m_project.version = version;
    }

    auto CurrentProjectManager::setCategory(const QString& category) -> void
    {
        this->m_project.category = category;
    }

    auto CurrentProjectManager::setStartScene(const QString& startScene) -> void
    {
        this->m_project.startScene = startScene;
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
