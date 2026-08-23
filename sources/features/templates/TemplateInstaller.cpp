#include "TemplateInstaller.hpp"
#include "PathResolver.hpp"
#include "TemplateUrlResolver.hpp"
#include "ZipExtractor.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QTemporaryFile>
#include <QDebug>

namespace
{
    auto postProcessExtraction(const QString& targetDirPath) -> bool
    {
        const QDir targetDir(targetDirPath);
        if (!targetDir.exists())
        {
            qWarning() << "[TemplateInstaller] Post-process failed: target directory does not exist:" << targetDirPath;
            return false;
        }

        const auto entries = targetDir.entryList(QDir::Dirs | QDir::Files | QDir::Hidden | QDir::NoDotAndDotDot);
        if (entries.size() != 1)
        {
            return true;
        }

        const QFileInfo singleEntry(targetDir.filePath(entries.first()));
        if (!singleEntry.isDir())
        {
            return true;
        }

        const auto extractedSubDirPath = singleEntry.absoluteFilePath();
        QDir extractedSubDir(extractedSubDirPath);

        const auto itemsToMove = extractedSubDir.entryList(QDir::Dirs | QDir::Files | QDir::Hidden | QDir::NoDotAndDotDot);
        for (const auto& item : itemsToMove)
        {
            const auto srcPath = extractedSubDir.filePath(item);
            const auto destPath = targetDir.filePath(item);

            if (!QFile::rename(srcPath, destPath))
            {
                qWarning() << "[TemplateInstaller] Failed to move item:" << srcPath << "to:" << destPath;
                return false;
            }
        }

        // Utiliser removeRecursively() au lieu de rmdir() pour supprimer proprement le dossier vidé
        if (!extractedSubDir.removeRecursively())
        {
            qWarning() << "[TemplateInstaller] Failed to remove unwrapped directory:" << extractedSubDirPath;
            return false;
        }

        return true;
    }
}

namespace noi_engine_editor
{
    TemplateInstaller::TemplateInstaller(QNetworkAccessManager& networkManager)
        : m_networkManager(networkManager)
    {
    }

    auto TemplateInstaller::install(
        const QString& templateId,
        const QString& repositoryUrl,
        const std::function<void(bool success)>& onFinished
    ) -> void
    {
        const auto downloadUrl = TemplateUrlResolver::zipUrl(repositoryUrl);
        const auto targetPath = QDir(PathResolver::templatesPath()).filePath(templateId);

        downloadZip(
            downloadUrl,
            [targetPath, templateId, onFinished](const QByteArray& zipData)
            {
                const auto success = extractAndUnwrap(targetPath, zipData);
                if (!success)
                {
                    qWarning() << "[TemplateInstaller] Extraction/Unwrapping failed for template:" << templateId << "- cleaning target path:" << targetPath;
                    cleanupFailedInstall(targetPath);
                }
                onFinished(success);
            },
            [targetPath, templateId, onFinished]()
            {
                qWarning() << "[TemplateInstaller] Download failed for template:" << templateId << "- cleaning target path:" << targetPath;
                cleanupFailedInstall(targetPath);
                onFinished(false);
            }
        );
    }

    auto TemplateInstaller::downloadZip(
        const QString& downloadUrl,
        const std::function<void(const QByteArray& zipData)>& onSuccess,
        const std::function<void()>& onError
    ) -> void
    {
        QNetworkRequest request((QUrl(downloadUrl)));
        request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

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
                qWarning() << "[TemplateInstaller] HTTP Download error for URL:" << downloadUrl
                           << "| Error:" << reply->errorString()
                           << "| HTTP Code:" << httpStatus;
                onError();
            }
        });
    }

    auto TemplateInstaller::extractAndUnwrap(const QString& targetPath, const QByteArray& zipData) -> bool
    {
        QTemporaryFile tempZip;
        if (!tempZip.open())
        {
            qWarning() << "[TemplateInstaller] Failed to create temporary ZIP file for writing.";
            return false;
        }

        tempZip.write(zipData);
        tempZip.flush();

        if (!noi_engine::zip_utils::unzip(tempZip.fileName(), targetPath))
        {
            qWarning() << "[TemplateInstaller] Failed to unzip file:" << tempZip.fileName() << "to destination:" << targetPath;
            return false;
        }

        return postProcessExtraction(targetPath);
    }

    auto TemplateInstaller::cleanupFailedInstall(const QString& targetPath) -> void
    {
        if (QDir dir(targetPath); dir.exists())
        {
            if (!dir.removeRecursively())
            {
                qWarning() << "[TemplateInstaller] Failed to clean up directory:" << targetPath;
            }
        }
    }
}