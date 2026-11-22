#include "ZipInstall.hpp"
#include "ZipExtractor.hpp"

#include <QDir>
#include <QFileInfo>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTemporaryFile>
#include <QDebug>

namespace noi_engine_editor::zip_install
{
    auto downloadZip(
        QNetworkAccessManager& networkManager,
        const QString& downloadUrl,
        const char* logTag,
        const std::function<void(const QByteArray& zipData)>& onSuccess,
        const std::function<void()>& onError
    ) -> void
    {
        QNetworkRequest request((QUrl(downloadUrl)));
        request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
        request.setRawHeader("User-Agent", "noi_engine_editor");
        // Without a timeout a stalled connection keeps the "installing" state on forever.
        request.setTransferTimeout(60'000);

        auto* reply = networkManager.get(request);

        QObject::connect(reply, &QNetworkReply::finished, [reply, downloadUrl, logTag, onSuccess, onError]()
        {
            reply->deleteLater();

            if (reply->error() == QNetworkReply::NoError)
            {
                onSuccess(reply->readAll());
            }
            else
            {
                const auto httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
                qWarning() << logTag << "HTTP Download error for URL:" << downloadUrl
                           << "| Error:" << reply->errorString()
                           << "| HTTP Code:" << httpStatus;
                onError();
            }
        });
    }

    auto extractZipData(const QString& targetPath, const QByteArray& zipData, const char* logTag) -> bool
    {
        QTemporaryFile tempZip;
        if (!tempZip.open())
        {
            qWarning() << logTag << "Failed to create temporary ZIP file for writing.";
            return false;
        }

        if (tempZip.write(zipData) != zipData.size() || !tempZip.flush())
        {
            qWarning() << logTag << "Failed to write the downloaded ZIP to disk.";
            return false;
        }

        if (!zip_utils::unzip(tempZip.fileName(), targetPath))
        {
            qWarning() << logTag << "Failed to unzip file:" << tempZip.fileName() << "to destination:" << targetPath;
            return false;
        }

        return true;
    }

    auto installZipData(
        const QString& targetPath,
        const QByteArray& zipData,
        const char* logTag,
        const std::function<bool(const QString& stagingPath)>& postProcess
    ) -> bool
    {
        const auto stagingPath = targetPath + QStringLiteral(".part");
        removeDirectory(stagingPath, logTag);

        const auto stagedOk = extractZipData(stagingPath, zipData, logTag) && (!postProcess || postProcess(stagingPath));
        if (!stagedOk)
        {
            removeDirectory(stagingPath, logTag);
            return false;
        }

        removeDirectory(targetPath, logTag);
        QDir().mkpath(QFileInfo(targetPath).absolutePath());
        if (!QDir().rename(stagingPath, targetPath))
        {
            qWarning() << logTag << "Failed to move" << stagingPath << "to" << targetPath;
            removeDirectory(stagingPath, logTag);
            return false;
        }

        return true;
    }

    auto removeDirectory(const QString& targetPath, const char* logTag) -> void
    {
        if (QDir dir(targetPath); dir.exists())
        {
            if (!dir.removeRecursively())
            {
                qWarning() << logTag << "Failed to clean up directory:" << targetPath;
            }
        }
    }
}
