#pragma once

#include <QByteArray>
#include <QString>
#include <QNetworkAccessManager>
#include <functional>

namespace noi_engine_editor
{
    class TemplateInstaller
    {
    public:
        explicit TemplateInstaller(QNetworkAccessManager& networkManager);

        auto install(
            const QString& templateId,
            const QString& version,
            const QString& repositoryUrl,
            const std::function<void(bool success)>& onFinished
        ) -> void;

    private:
        auto downloadZip(
            const QString& downloadUrl,
            const std::function<void(const QByteArray& zipData)>& onSuccess,
            const std::function<void()>& onError
        ) -> void;

        static auto extractAndUnwrap(const QString& targetPath, const QByteArray& zipData) -> bool;
        static auto cleanupFailedInstall(const QString& targetPath) -> void;

        QNetworkAccessManager& m_networkManager;
    };
}
