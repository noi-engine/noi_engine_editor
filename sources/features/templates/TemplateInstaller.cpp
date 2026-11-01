#include "TemplateInstaller.hpp"
#include "PathResolver.hpp"
#include "TemplateUrlResolver.hpp"
#include "ZipInstall.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QDebug>

namespace
{
    constexpr auto LOG_TAG = "[TemplateInstaller]";

    auto postProcessExtraction(const QString& targetDirPath) -> bool
    {
        const QDir targetDir(targetDirPath);
        if (!targetDir.exists())
        {
            qWarning() << LOG_TAG << "Post-process failed: target directory does not exist:" << targetDirPath;
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
                qWarning() << LOG_TAG << "Failed to move item:" << srcPath << "to:" << destPath;
                return false;
            }
        }

        if (!extractedSubDir.removeRecursively())
        {
            qWarning() << LOG_TAG << "Failed to remove unwrapped directory:" << extractedSubDirPath;
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
        const QString& version,
        const QString& repositoryUrl,
        const std::function<void(bool success)>& onFinished
    ) -> void
    {
        const auto downloadUrl = TemplateUrlResolver::zipUrl(repositoryUrl);
        const auto targetPath = PathResolver::templateAbsolutePath(templateId, version);

        zip_install::downloadZip(
            m_networkManager,
            downloadUrl,
            LOG_TAG,
            [targetPath, templateId, onFinished](const QByteArray& zipData)
            {
                const auto success = extractAndUnwrap(targetPath, zipData);
                if (!success)
                {
                    qWarning() << LOG_TAG << "Extraction/Unwrapping failed for template:" << templateId << "- cleaning target path:" << targetPath;
                    zip_install::removeDirectory(targetPath, LOG_TAG);
                }
                onFinished(success);
            },
            [targetPath, templateId, onFinished]()
            {
                qWarning() << LOG_TAG << "Download failed for template:" << templateId << "- cleaning target path:" << targetPath;
                zip_install::removeDirectory(targetPath, LOG_TAG);
                onFinished(false);
            }
        );
    }

    auto TemplateInstaller::extractAndUnwrap(const QString& targetPath, const QByteArray& zipData) -> bool
    {
        return zip_install::extractZipData(targetPath, zipData, LOG_TAG) && postProcessExtraction(targetPath);
    }
}
