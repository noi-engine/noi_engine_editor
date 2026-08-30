#include "ToolsManager.hpp"
#include "ToolUrlResolver.hpp"
#include "ToolInstaller.hpp"
#include "PathResolver.hpp"

#include <QDir>
#include <memory>

namespace noi_engine_editor
{
    ToolsManager::ToolsManager(QObject* parent) : QObject(parent)
    {
    }

    auto ToolsManager::isInstallingNoiEngine() const -> bool
    {
        return m_isInstallingNoiEngine;
    }

    auto ToolsManager::isInstallingResourceCompiler() const -> bool
    {
        return m_isInstallingResourceCompiler;
    }

    auto ToolsManager::setInstallingNoiEngine(bool installing) -> void
    {
        m_isInstallingNoiEngine = installing;
        emit isInstallingNoiEngineChanged();
    }

    auto ToolsManager::setInstallingResourceCompiler(bool installing) -> void
    {
        m_isInstallingResourceCompiler = installing;
        emit isInstallingResourceCompilerChanged();
    }

    auto ToolsManager::isNoiEngineInstalled(const QString& version) const -> bool
    {
        return QDir(PathResolver::noiEngineContentPath(version)).exists();
    }

    auto ToolsManager::isResourceCompilerInstalled(const QString& version) const -> bool
    {
        return QDir(PathResolver::resourceCompilerContentPath(version)).exists();
    }

    auto ToolsManager::installedNoiEngineVersions() const -> QVariantList
    {
        QVariantList result;
        for (const auto& version : QDir(PathResolver::noiEngineRootPath()).entryList(QDir::Dirs | QDir::NoDotAndDotDot))
        {
            result.append(version);
        }
        return result;
    }

    auto ToolsManager::installedResourceCompilerVersions() const -> QVariantList
    {
        QVariantList result;
        for (const auto& version : QDir(PathResolver::resourceCompilerRootPath()).entryList(
                 QDir::Dirs | QDir::NoDotAndDotDot))
        {
            result.append(version);
        }
        return result;
    }

    auto ToolsManager::installNoiEngine(const QString& version) -> void
    {
        if (m_isInstallingNoiEngine) return;
        setInstallingNoiEngine(true);

        const auto installer = std::make_shared<ToolInstaller>(m_networkManager);
        installer->install(
            ToolUrlResolver::noiEngineDownloadUrl(version),
            PathResolver::noiEnginePath(version),
            [this, version](const bool success)
            {
                setInstallingNoiEngine(false);
                emit installFinished("noi_engine", version, success);
            }
        );
    }

    auto ToolsManager::installResourceCompiler(const QString& version) -> void
    {
        if (m_isInstallingResourceCompiler) return;
        setInstallingResourceCompiler(true);

        const auto installer = std::make_shared<ToolInstaller>(m_networkManager);
        installer->install(
            ToolUrlResolver::resourceCompilerDownloadUrl(version),
            PathResolver::resourceCompilerPath(version),
            [this, version](const bool success)
            {
                setInstallingResourceCompiler(false);
                emit installFinished("resource_compiler", version, success);
            }
        );
    }
}
