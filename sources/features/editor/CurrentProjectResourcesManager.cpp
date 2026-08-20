#include "CurrentProjectResourcesManager.hpp"
#include <QDirIterator>

namespace noi_engine_editor
{
    CurrentProjectResourcesManager::CurrentProjectResourcesManager(QObject* parent)
        : QObject(parent)
    {
    }

    auto CurrentProjectResourcesManager::createFolder(const QString& parentFolderPath,
                                                      const QString& folderName) -> bool
    {
        QDir dir(parentFolderPath);
        if (!dir.exists())
        {
            return false;
        }
        return dir.mkdir(folderName);
    }

    auto CurrentProjectResourcesManager::renameItem(const QString& itemPath, const QString& newName) -> bool
    {
        QFileInfo fileInfo(itemPath);
        if (!fileInfo.exists())
        {
            return false;
        }

        auto newPath = fileInfo.absoluteDir().filePath(newName);
        return QDir().rename(itemPath, newPath);
    }

    auto CurrentProjectResourcesManager::deleteItem(const QString& itemPath) -> bool
    {
        QFileInfo fileInfo(itemPath);

        if (!fileInfo.exists())
        {
            return false;
        }

        if (fileInfo.isDir())
        {
            return QDir(itemPath).removeRecursively();
        }
        return QFile::remove(itemPath);
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

    auto CurrentProjectResourcesManager::importPaths(const QList<QString>& paths, const QString& targetFolderPath) -> bool
    {
        auto targetDir = QDir::cleanPath(targetFolderPath);
        auto allSuccess = true;

        for (const auto& path : paths)
        {
            auto srcPath = QDir::cleanPath(path);

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
