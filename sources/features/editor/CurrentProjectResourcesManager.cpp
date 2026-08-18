#include "CurrentProjectResourcesManager.hpp"
#include <QUrl>
#include <QDirIterator>

namespace noi_engine_editor
{
    CurrentProjectResourcesManager::CurrentProjectResourcesManager(QObject* parent)
        : QObject(parent)
    {
    }

    auto CurrentProjectResourcesManager::urlToLocalPath(const QString& urlOrPath) const -> QString
    {
        if (urlOrPath.startsWith(QStringLiteral("file:")))
        {
            return QUrl(urlOrPath).toLocalFile();
        }
        return urlOrPath;
    }

    auto CurrentProjectResourcesManager::createFolder(const QString& parentFolderPath,
                                                      const QString& folderName) -> bool
    {
        auto parentPath = urlToLocalPath(parentFolderPath);
        QDir dir(parentPath);
        if (!dir.exists())
        {
            return false;
        }
        return dir.mkdir(folderName);
    }

    auto CurrentProjectResourcesManager::renameItem(const QString& itemPath, const QString& newName) -> bool
    {
        auto localPath = urlToLocalPath(itemPath);
        QFileInfo fileInfo(localPath);
        if (!fileInfo.exists())
        {
            return false;
        }

        auto newPath = fileInfo.absoluteDir().filePath(newName);
        return QDir().rename(localPath, newPath);
    }

    auto CurrentProjectResourcesManager::deleteItem(const QString& itemPath) -> bool
    {
        auto localPath = urlToLocalPath(itemPath);
        QFileInfo fileInfo(localPath);

        if (!fileInfo.exists())
        {
            return false;
        }

        if (fileInfo.isDir())
        {
            return QDir(localPath).removeRecursively();
        }
        return QFile::remove(localPath);
    }

    auto CurrentProjectResourcesManager::copyRecursively(const QString& srcFilePath, const QString& tgtFilePath) -> bool
    {
        QFileInfo srcFileInfo(srcFilePath);

        if (QDir::cleanPath(srcFilePath) == QDir::cleanPath(tgtFilePath))
        {
            return true;
        }

        if (srcFileInfo.isDir())
        {
            QDir targetDir(tgtFilePath);
            if (!targetDir.exists())
            {
                if (!QDir().mkpath(tgtFilePath))
                {
                    return false;
                }
            }

            QDir sourceDir(srcFilePath);
            auto fileNames = sourceDir.entryList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden);

            for (const auto& fileName : fileNames)
            {
                auto newSrcPath = QDir::cleanPath(srcFilePath + QStringLiteral("/") + fileName);
                auto newTgtPath = QDir::cleanPath(tgtFilePath + QStringLiteral("/") + fileName);

                if (newTgtPath.startsWith(newSrcPath + QStringLiteral("/")))
                {
                    continue;
                }

                if (!copyRecursively(newSrcPath, newTgtPath))
                {
                    return false;
                }
            }
        }
        else
        {
            QFileInfo tgtFileInfo(tgtFilePath);
            QDir().mkpath(tgtFileInfo.absolutePath());

            if (QFile::exists(tgtFilePath))
            {
                QFile::remove(tgtFilePath);
            }
            if (!QFile::copy(srcFilePath, tgtFilePath))
            {
                return false;
            }
        }
        return true;
    }

    auto CurrentProjectResourcesManager::importPaths(const QList<QUrl>& urls, const QString& targetFolderPath) -> bool
    {
        auto targetDir = QDir::cleanPath(urlToLocalPath(targetFolderPath));
        auto allSuccess = true;

        QDir destinationDir(targetDir);
        if (!destinationDir.exists())
        {
            destinationDir.mkpath(targetDir);
        }

        for (const auto& url : urls)
        {
            auto srcPath = QDir::cleanPath(url.isLocalFile() ? url.toLocalFile() : urlToLocalPath(url.toString()));

            QFileInfo srcInfo(srcPath);
            if (!srcInfo.exists())
            {
                allSuccess = false;
                continue;
            }

            auto destPath = QDir::cleanPath(targetDir + QStringLiteral("/") + srcInfo.fileName());

            if (srcInfo.isDir() && (targetDir == srcPath || targetDir.startsWith(srcPath + QStringLiteral("/"))))
            {
                allSuccess = false;
                continue;
            }

            if (!copyRecursively(srcPath, destPath))
            {
                allSuccess = false;
            }
        }
        return allSuccess;
    }

    QStringList CurrentProjectResourcesManager::getAllScenesRecursively(const QString& rootPath)
    {
        QStringList sceneFiles;
        QDirIterator it(rootPath, QStringList() << "*.scene", QDir::Files, QDirIterator::Subdirectories);

        while (it.hasNext()) {
            sceneFiles.append(it.next());
        }
        return sceneFiles;
    }
}
