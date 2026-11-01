#include "ZipInstall.hpp"
#include "ZipExtractor.hpp"

#include <QDir>
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

        tempZip.write(zipData);
        tempZip.flush();

        if (!noi_engine::zip_utils::unzip(tempZip.fileName(), targetPath))
        {
            qWarning() << logTag << "Failed to unzip file:" << tempZip.fileName() << "to destination:" << targetPath;
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
