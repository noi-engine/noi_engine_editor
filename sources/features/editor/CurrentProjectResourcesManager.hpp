#pragma once

#include <QQmlEngine>
#include <QString>
#include <QUrl>

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
        Q_INVOKABLE [[nodiscard]] auto importPaths(const QList<QUrl>& urls, const QString& targetFolderPath) -> bool;

    private:
        [[nodiscard]] auto urlToLocalPath(const QString& urlOrPath) const -> QString;
        [[nodiscard]] auto copyRecursively(const QString& srcFilePath, const QString& tgtFilePath) -> bool;
    };
}