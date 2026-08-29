#include "ToolsManager.hpp"
#include "ToolUrlResolver.hpp"
#include "ToolInstaller.hpp"
#include "PathResolver.hpp"

#include <QDir>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <memory>

namespace noi_engine_editor
{
    ToolsManager::ToolsManager(QObject* parent) : QObject(parent)
    {
    }

    auto ToolsManager::isFetchingVersions() const -> bool
    {
        return m_isFetchingVersions;
    }

    auto ToolsManager::isInstalling() const -> bool
    {
        return m_isInstalling;
    }

    auto ToolsManager::latestNoiEngineVersion() const -> QString
    {
        return m_latestNoiEngineVersion;
    }

    auto ToolsManager::latestResourceCompilerVersion() const -> QString
    {
        return m_latestResourceCompilerVersion;
    }

    auto ToolsManager::setFetchingVersions(bool fetching) -> void
    {
        if (m_isFetchingVersions == fetching) return;
        m_isFetchingVersions = fetching;
        emit isFetchingVersionsChanged();
    }

    auto ToolsManager::setInstalling(bool installing) -> void
    {
        if (m_isInstalling == installing) return;
        m_isInstalling = installing;
        emit isInstallingChanged();
    }

    auto ToolsManager::fetchAssetInfo(
        const QString& apiUrl,
        const QString& assetName,
        const std::function<void(const QString& tag, const QString& downloadUrl)>& onSuccess,
        const std::function<void()>& onError
    ) -> void
    {
        QNetworkRequest request((QUrl(apiUrl)));
        request.setRawHeader("User-Agent", "noi_engine_editor");
        request.setRawHeader("Accept", "application/vnd.github+json");

        auto* reply = m_networkManager.get(request);

        connect(reply, &QNetworkReply::finished, this, [reply, assetName, onSuccess, onError]()
        {
            reply->deleteLater();

            if (reply->error() != QNetworkReply::NoError)
            {
                onError();
                return;
            }

            const auto doc = QJsonDocument::fromJson(reply->readAll());
            if (!doc.isObject())
            {
                onError();
                return;
            }

            const auto object = doc.object();
            const auto tag = object.value("tag_name").toString();
            const auto assets = object.value("assets").toArray();

            for (const auto& assetValue : assets)
            {
                const auto asset = assetValue.toObject();
                if (asset.value("name").toString() == assetName)
                {
                    onSuccess(tag, asset.value("browser_download_url").toString());
                    return;
                }
            }

            onError();
        });
    }

    auto ToolsManager::fetchLatestVersionsInternal(const std::function<void(bool success)>& onDone) -> void
    {
        setFetchingVersions(true);

        auto remaining = std::make_shared<int>(2);
        auto anyFailed = std::make_shared<bool>(false);

        auto checkDone = [this, remaining, anyFailed, onDone]()
        {
            (*remaining)--;
            if (*remaining > 0) return;

            setFetchingVersions(false);

            if (*anyFailed)
            {
                emit fetchFailed(tr("Failed to fetch the latest tool versions"));
            }
            else
            {
                emit versionsFetched();
            }

            onDone(!*anyFailed);
        };

        fetchAssetInfo(
            ToolUrlResolver::noiEngineReleaseApiUrl("latest"),
            ToolUrlResolver::currentPlatformNoiEngineAssetName(),
            [this, checkDone](const QString& tag, const QString& downloadUrl)
            {
                m_latestNoiEngineVersion = tag;
                m_latestNoiEngineDownloadUrl = downloadUrl;
                checkDone();
            },
            [anyFailed, checkDone]()
            {
                *anyFailed = true;
                checkDone();
            }
        );

        fetchAssetInfo(
            ToolUrlResolver::resourceCompilerReleaseApiUrl("latest"),
            ToolUrlResolver::resourceCompilerAssetName(),
            [this, checkDone](const QString& tag, const QString& downloadUrl)
            {
                m_latestResourceCompilerVersion = tag;
                m_latestResourceCompilerDownloadUrl = downloadUrl;
                checkDone();
            },
            [anyFailed, checkDone]()
            {
                *anyFailed = true;
                checkDone();
            }
        );
    }

    auto ToolsManager::fetchLatestVersions() -> void
    {
        fetchLatestVersionsInternal([](bool) {});
    }

    auto ToolsManager::isNoiEngineInstalled(const QString& version) const -> bool
    {
        return QDir(PathResolver::noiEngineContentPath(version)).exists();
    }

    auto ToolsManager::isResourceCompilerInstalled(const QString& version) const -> bool
    {
        return QDir(PathResolver::resourceCompilerPath(version)).exists();
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
        for (const auto& version : QDir(PathResolver::resourceCompilerRootPath()).entryList(QDir::Dirs | QDir::NoDotAndDotDot))
        {
            result.append(version);
        }
        return result;
    }

    auto ToolsManager::installNoiEngine(const QString& version) -> void
    {
        if (m_isInstalling) return;
        setInstalling(true);

        auto install = [this](const QString& tag, const QString& downloadUrl)
        {
            auto installer = std::make_shared<ToolInstaller>(m_networkManager);
            installer->install(downloadUrl, PathResolver::noiEngineContentPath(tag), [this, tag, installer](bool success)
            {
                setInstalling(false);
                emit installFinished("noi_engine", tag, success);
            });
        };

        if (version == m_latestNoiEngineVersion && !m_latestNoiEngineDownloadUrl.isEmpty())
        {
            install(version, m_latestNoiEngineDownloadUrl);
            return;
        }

        fetchAssetInfo(
            ToolUrlResolver::noiEngineReleaseApiUrl(version),
            ToolUrlResolver::currentPlatformNoiEngineAssetName(),
            install,
            [this, version]()
            {
                setInstalling(false);
                emit installFinished("noi_engine", version, false);
            }
        );
    }

    auto ToolsManager::installResourceCompiler(const QString& version) -> void
    {
        if (m_isInstalling) return;
        setInstalling(true);

        auto install = [this](const QString& tag, const QString& downloadUrl)
        {
            auto installer = std::make_shared<ToolInstaller>(m_networkManager);
            installer->install(downloadUrl, PathResolver::resourceCompilerPath(tag), [this, tag, installer](bool success)
            {
                setInstalling(false);
                emit installFinished("resource_compiler", tag, success);
            });
        };

        if (version == m_latestResourceCompilerVersion && !m_latestResourceCompilerDownloadUrl.isEmpty())
        {
            install(version, m_latestResourceCompilerDownloadUrl);
            return;
        }

        fetchAssetInfo(
            ToolUrlResolver::resourceCompilerReleaseApiUrl(version),
            ToolUrlResolver::resourceCompilerAssetName(),
            install,
            [this, version]()
            {
                setInstalling(false);
                emit installFinished("resource_compiler", version, false);
            }
        );
    }

    auto ToolsManager::removeNoiEngineVersion(const QString& version) -> void
    {
        QDir(PathResolver::noiEnginePath(version)).removeRecursively();
    }

    auto ToolsManager::removeResourceCompilerVersion(const QString& version) -> void
    {
        QDir(PathResolver::resourceCompilerPath(version)).removeRecursively();
    }

    auto ToolsManager::ensureLatestToolsInstalled() -> void
    {
        if (m_isInstalling) return;

        auto proceedToInstall = [this]()
        {
            const auto engineVersion = m_latestNoiEngineVersion;
            const auto compilerVersion = m_latestResourceCompilerVersion;

            if (engineVersion.isEmpty() || compilerVersion.isEmpty())
            {
                emit toolsReady(false);
                return;
            }

            const auto engineNeeded = !isNoiEngineInstalled(engineVersion);
            const auto compilerNeeded = !isResourceCompilerInstalled(compilerVersion);

            if (!engineNeeded && !compilerNeeded)
            {
                emit toolsReady(true);
                return;
            }

            setInstalling(true);

            auto remaining = std::make_shared<int>((engineNeeded ? 1 : 0) + (compilerNeeded ? 1 : 0));
            auto anyFailed = std::make_shared<bool>(false);

            auto checkDone = [this, remaining, anyFailed]()
            {
                (*remaining)--;
                if (*remaining > 0) return;

                setInstalling(false);
                emit toolsReady(!*anyFailed);
            };

            if (engineNeeded)
            {
                auto installer = std::make_shared<ToolInstaller>(m_networkManager);
                installer->install(
                    m_latestNoiEngineDownloadUrl,
                    PathResolver::noiEngineContentPath(engineVersion),
                    [this, engineVersion, installer, anyFailed, checkDone](bool success)
                    {
                        if (!success) *anyFailed = true;
                        emit installFinished("noi_engine", engineVersion, success);
                        checkDone();
                    }
                );
            }

            if (compilerNeeded)
            {
                auto installer = std::make_shared<ToolInstaller>(m_networkManager);
                installer->install(
                    m_latestResourceCompilerDownloadUrl,
                    PathResolver::resourceCompilerPath(compilerVersion),
                    [this, compilerVersion, installer, anyFailed, checkDone](bool success)
                    {
                        if (!success) *anyFailed = true;
                        emit installFinished("resource_compiler", compilerVersion, success);
                        checkDone();
                    }
                );
            }
        };

        if (m_latestNoiEngineVersion.isEmpty() || m_latestResourceCompilerVersion.isEmpty())
        {
            fetchLatestVersionsInternal([this, proceedToInstall](bool success)
            {
                if (!success)
                {
                    emit toolsReady(false);
                    return;
                }
                proceedToInstall();
            });

            return;
        }

        proceedToInstall();
    }
}
