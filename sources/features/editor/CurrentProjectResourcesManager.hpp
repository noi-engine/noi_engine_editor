#pragma once

#include <QQmlEngine>
#include <QString>

namespace noi_engine_editor
{
    class CurrentProjectResourcesManager : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

    public:
        explicit CurrentProjectResourcesManager(QObject* parent = nullptr);

        Q_INVOKABLE [[nodiscard]] auto createFolder(const QString& parentFolderPath, const QString& folderName) -> bool;
        Q_INVOKABLE [[nodiscard]] auto renameItem(const QString& itemPath, const QString& newName) -> bool;
        Q_INVOKABLE [[nodiscard]] auto deleteItem(const QString& itemPath) -> bool;
        Q_INVOKABLE [[nodiscard]] auto importPaths(const QList<QString>& paths, const QString& targetFolderPath) -> bool;
        Q_INVOKABLE QStringList getAllScenesRecursively(const QString& rootPath);

        // Writes a brand-new file with the given text content. Fails (returns false) if
        // parentFolderPath doesn't exist or a file with that name is already there.
        Q_INVOKABLE [[nodiscard]] auto createFile(const QString& parentFolderPath, const QString& fileName,
                                                    const QString& content) -> bool;
        // Copies itemPath to a sibling file/folder named newName (same directory). Fails if
        // itemPath doesn't exist or newName is already taken.
        Q_INVOKABLE [[nodiscard]] auto duplicateItem(const QString& itemPath, const QString& newName) -> bool;

        // Scene-specific rename: renames the .scene file to newName (extension added if
        // missing) AND patches the JSON "name" field inside it to match, so the file name and
        // the scene's own name stay in sync. Fails if itemPath doesn't exist, the target file
        // name is already taken, or the file isn't valid JSON (the rename itself still succeeds
        // in that last case - only the name-field patch is skipped).
        Q_INVOKABLE [[nodiscard]] auto renameScene(const QString& itemPath, const QString& newName) -> bool;

        // Generic file I/O for editor tooling that needs to read-modify-write an existing file
        // (e.g. merging a new texture declaration into a scene's resources block) - unlike
        // createFile(), writeFile() always overwrites. readFile() returns an empty string for a
        // missing/unreadable file, which is indistinguishable from a genuinely empty file; callers
        // that care should check existence separately.
        Q_INVOKABLE [[nodiscard]] auto readFile(const QString& path) -> QString;
        Q_INVOKABLE [[nodiscard]] auto writeFile(const QString& path, const QString& content) -> bool;

    private:
        [[nodiscard]] auto copyRecursively(const QString& srcFilePath, const QString& tgtFilePath) -> bool;
    };
}