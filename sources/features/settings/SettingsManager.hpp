#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>

namespace noi_engine_editor
{
    class SettingsManager : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

        Q_PROPERTY(QString defaultProjectsPath READ defaultProjectsPath WRITE setDefaultProjectsPath NOTIFY defaultProjectsPathChanged)
        // Command that opens a folder / file in the user's code editor ("code", "clion --line 1").
        // Empty: the editor looks for a known one.
        Q_PROPERTY(QString codeEditorCommand READ codeEditorCommand WRITE setCodeEditorCommand NOTIFY codeEditorCommandChanged)

    public:
        explicit SettingsManager(QObject* parent = nullptr);

        [[nodiscard]] auto defaultProjectsPath() const -> QString;

        auto setDefaultProjectsPath(const QString& path) -> void;

        [[nodiscard]] auto codeEditorCommand() const -> QString;
        auto setCodeEditorCommand(const QString& command) -> void;

    signals:
        void defaultProjectsPathChanged();
        void codeEditorCommandChanged();

    private:
        QString m_defaultProjectsPath;
        QString m_codeEditorCommand;
    };
}
