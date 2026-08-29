#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QVariantList>
#include <QNetworkAccessManager>
#include <functional>

namespace noi_engine_editor
{
    class ToolsManager : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

        Q_PROPERTY(bool isFetchingVersions READ isFetchingVersions NOTIFY isFetchingVersionsChanged)
        Q_PROPERTY(bool isInstalling READ isInstalling NOTIFY isInstallingChanged)
        Q_PROPERTY(QString latestNoiEngineVersion READ latestNoiEngineVersion NOTIFY versionsFetched)
        Q_PROPERTY(QString latestResourceCompilerVersion READ latestResourceCompilerVersion NOTIFY versionsFetched)

    public:
        explicit ToolsManager(QObject* parent = nullptr);

        [[nodiscard]] auto isFetchingVersions() const -> bool;
        [[nodiscard]] auto isInstalling() const -> bool;
        [[nodiscard]] auto latestNoiEngineVersion() const -> QString;
        [[nodiscard]] auto latestResourceCompilerVersion() const -> QString;

        Q_INVOKABLE auto fetchLatestVersions() -> void;

        Q_INVOKABLE [[nodiscard]] auto isNoiEngineInstalled(const QString& version) const -> bool;
        Q_INVOKABLE [[nodiscard]] auto isResourceCompilerInstalled(const QString& version) const -> bool;
        Q_INVOKABLE [[nodiscard]] auto installedNoiEngineVersions() const -> QVariantList;
        Q_INVOKABLE [[nodiscard]] auto installedResourceCompilerVersions() const -> QVariantList;

        Q_INVOKABLE auto installNoiEngine(const QString& version) -> void;
        Q_INVOKABLE auto installResourceCompiler(const QString& version) -> void;
        Q_INVOKABLE auto removeNoiEngineVersion(const QString& version) -> void;
        Q_INVOKABLE auto removeResourceCompilerVersion(const QString& version) -> void;

        Q_INVOKABLE auto ensureLatestToolsInstalled() -> void;

    signals:
        auto isFetchingVersionsChanged() -> void;
        auto isInstallingChanged() -> void;
        auto versionsFetched() -> void;
        auto fetchFailed(const QString& error) -> void;
        auto installFinished(const QString& tool, const QString& version, bool success) -> void;
        auto toolsReady(bool success) -> void;

    private:
        auto setFetchingVersions(bool fetching) -> void;
        auto setInstalling(bool installing) -> void;

        auto fetchLatestVersionsInternal(const std::function<void(bool success)>& onDone) -> void;

        auto fetchAssetInfo(
            const QString& apiUrl,
            const QString& assetName,
            const std::function<void(const QString& tag, const QString& downloadUrl)>& onSuccess,
            const std::function<void()>& onError
        ) -> void;

        QNetworkAccessManager m_networkManager;

        bool m_isFetchingVersions = false;
        bool m_isInstalling = false;

        QString m_latestNoiEngineVersion;
        QString m_latestResourceCompilerVersion;
        QString m_latestNoiEngineDownloadUrl;
        QString m_latestResourceCompilerDownloadUrl;
    };
}
