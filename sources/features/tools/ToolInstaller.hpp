#pragma once

#include <QNetworkAccessManager>
#include <functional>

namespace noi_engine_editor
{
    class ToolInstaller
    {
    public:
        explicit ToolInstaller(QNetworkAccessManager& networkManager);

        auto install(const QString& downloadUrl, const QString& targetPath, const std::function<void(bool success)>& onFinished) -> void;

    private:
        auto downloadZip(
            const QString& downloadUrl,
            const std::function<void(const QByteArray& zipData)>& onSuccess,
            const std::function<void()>& onError
        ) -> void;

        static auto extract(const QString& targetPath, const QByteArray& zipData) -> bool;
        static auto cleanupFailedInstall(const QString& targetPath) -> void;

        QNetworkAccessManager& m_networkManager;
    };
}
