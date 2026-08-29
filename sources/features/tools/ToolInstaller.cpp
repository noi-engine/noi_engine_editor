#include "ToolInstaller.hpp"
#include "ZipExtractor.hpp"

#include <QDir>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QTemporaryFile>
#include <QDebug>

namespace noi_engine_editor
{
    ToolInstaller::ToolInstaller(QNetworkAccessManager& networkManager)
        : m_networkManager(networkManager)
    {
    }

    auto ToolInstaller::install(
        const QString& downloadUrl,
        const QString& targetPath,
        const std::function<void(bool success)>& onFinished
    ) -> void
    {
        downloadZip(
            downloadUrl,
            [targetPath, onFinished](const QByteArray& zipData)
            {
                const auto success = extract(targetPath, zipData);
                if (!success)
                {
                    qWarning() << "[ToolInstaller] Extraction failed for target:" << targetPath;
                    cleanupFailedInstall(targetPath);
                }
                onFinished(success);
            },
            [targetPath, onFinished]()
            {
                qWarning() << "[ToolInstaller] Download failed for target:" << targetPath;
                cleanupFailedInstall(targetPath);
                onFinished(false);
            }
        );
    }

    auto ToolInstaller::downloadZip(
        const QString& downloadUrl,
        const std::function<void(const QByteArray& zipData)>& onSuccess,
        const std::function<void()>& onError
    ) -> void
    {
        QNetworkRequest request((QUrl(downloadUrl)));
        request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
        request.setRawHeader("User-Agent", "noi_engine_editor");

        auto* reply = m_networkManager.get(request);

        QObject::connect(reply, &QNetworkReply::finished, [reply, downloadUrl, onSuccess, onError]()
        {
            reply->deleteLater();

            if (reply->error() == QNetworkReply::NoError)
            {
                onSuccess(reply->readAll());
            }
            else
            {
                const auto httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
                qWarning() << "[ToolInstaller] HTTP Download error for URL:" << downloadUrl
                           << "| Error:" << reply->errorString()
                           << "| HTTP Code:" << httpStatus;
                onError();
            }
        });
    }

    auto ToolInstaller::extract(const QString& targetPath, const QByteArray& zipData) -> bool
    {
        QTemporaryFile tempZip;
        if (!tempZip.open())
        {
            qWarning() << "[ToolInstaller] Failed to create temporary ZIP file for writing.";
            return false;
        }

        tempZip.write(zipData);
        tempZip.flush();

        if (!noi_engine::zip_utils::unzip(tempZip.fileName(), targetPath))
        {
            qWarning() << "[ToolInstaller] Failed to unzip file:" << tempZip.fileName() << "to destination:" << targetPath;
            return false;
        }

        return true;
    }

    auto ToolInstaller::cleanupFailedInstall(const QString& targetPath) -> void
    {
        if (QDir dir(targetPath); dir.exists())
        {
            if (!dir.removeRecursively())
            {
                qWarning() << "[ToolInstaller] Failed to clean up directory:" << targetPath;
            }
        }
    }
}
