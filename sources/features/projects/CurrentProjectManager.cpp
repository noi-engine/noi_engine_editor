#include "CurrentProjectManager.hpp"

#include <QDir>
#include <QFile>
#include <QJsonObject>

#include "../../common/utils/EditorBridgeResolver.hpp"
#include "../../common/utils/JsonSerializer.hpp"
#include "../../common/utils/JsonIO.hpp"
#include "../../common/utils/PathResolver.hpp"

namespace noi_engine_editor
{
    CurrentProjectManager::CurrentProjectManager(QObject* parent) : QObject(parent)
    {
    }

    auto CurrentProjectManager::failOpen(const QString& reason, const QString& missingEditorBridgeVersion) -> bool
    {
        qWarning() << "[CurrentProjectManager] Can't open project:" << reason;
        m_lastOpenError = reason;
        m_missingEditorBridgeVersion = missingEditorBridgeVersion;
        emit lastOpenErrorChanged();
        emit projectOpenFailed(reason);
        return false;
    }

    auto CurrentProjectManager::isProjectFolder(const QString& path) -> bool
    {
        return QFile::exists(PathResolver::projectFilePath(path));
    }

    auto CurrentProjectManager::openProject(const QString& path) -> bool
    {
        ProjectInfo project;
        try
        {
            const auto doc = JsonIO::read(PathResolver::projectFilePath(path));
            if (!doc.isObject())
            {
                return failOpen(tr("Invalid project file"));
            }

            project = Json::deserialize<ProjectInfo>(doc.object());
        }
        catch (const std::runtime_error &e)
        {
            qWarning() << "[CurrentProjectManager] Failed to read project:" << e.what();
            return failOpen(tr("Invalid project file"));
        }

        if (const auto bridge = EditorBridgeResolver::resolve(project.editorBridgeVersion, project.engineVersion);
            bridge.libraryPath.isEmpty())
        {
            return failOpen(bridge.error, bridge.notInstalled ? project.editorBridgeVersion : QString{});
        }

        m_lastOpenError.clear();
        m_missingEditorBridgeVersion.clear();
        emit lastOpenErrorChanged();

        m_project = project;
        m_path = path;
        m_isOpen = true;

        emit projectChanged();
        emit nameChanged();
        emit versionChanged();
        emit categoryChanged();
        emit startSceneChanged();
        emit windowWidthChanged();
        emit windowHeightChanged();
        emit engineVersionChanged();
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
            qWarning() << "[CurrentProjectManager] Failed to save project:" << e.what();
            return false;
        }
    }

    auto CurrentProjectManager::resourcesPath() const -> QString
    {
        return PathResolver::projectResourcesPath(this->m_path);
    }

    auto CurrentProjectManager::scriptsLibraryPath() const -> QString
    {
        if (m_project.scriptsLibrary.isEmpty())
        {
            return {};
        }

        return QDir(this->m_path).filePath(m_project.scriptsLibrary);
    }

    auto CurrentProjectManager::bridgeLibraryPath() const -> QString
    {
        if (!m_isOpen)
        {
            return {};
        }

        const auto resolution = EditorBridgeResolver::resolve(m_project.editorBridgeVersion, m_project.engineVersion);
        if (resolution.libraryPath.isEmpty())
        {
            qWarning() << "[CurrentProjectManager] Can't use the editor bridge:" << resolution.error;
        }
        return resolution.libraryPath;
    }

    auto CurrentProjectManager::engineLibraryPath() const -> QString
    {
        if (!m_isOpen)
        {
            return {};
        }

        // QLibrary adds the platform prefix/suffix (libnoi_engine.so / .dylib).
        return QDir(this->m_path).filePath(".noi_engine/libs/noi_engine");
    }

    auto CurrentProjectManager::closeProject() -> void
    {
        m_path.clear();
        m_isOpen = false;
        m_project = ProjectInfo{};

        emit projectChanged();
        emit engineVersionChanged();
    }

    auto CurrentProjectManager::lastOpenError() const -> QString
    {
        return m_lastOpenError;
    }

    auto CurrentProjectManager::missingEditorBridgeVersion() const -> QString
    {
        return m_missingEditorBridgeVersion;
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

    auto CurrentProjectManager::engineVersion() const -> QString
    {
        return m_project.engineVersion;
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
