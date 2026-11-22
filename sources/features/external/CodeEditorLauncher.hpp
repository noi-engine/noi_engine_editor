#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>

namespace noi_engine_editor
{
    // Opens the project (or one of its script files) in the user's own code editor, the one set
    // in Settings or else the first known editor found on the machine.
    class CodeEditorLauncher : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

    public:
        explicit CodeEditorLauncher(QObject* parent = nullptr);

        // Opens `projectPath` (a folder) in the code editor, with `filePath` open in it when given.
        // False when no editor could be started.
        Q_INVOKABLE auto open(const QString& projectPath, const QString& filePath = {}) -> bool;

        // The source file of a script ("player_script" -> <project>/sources/scripts/player_script.cpp),
        // or empty when there is none.
        Q_INVOKABLE [[nodiscard]] auto scriptFile(const QString& projectPath, const QString& scriptName) const -> QString;

        // What would be started: the Settings command, else the name of the editor found, else empty.
        Q_INVOKABLE [[nodiscard]] auto detectedEditor() const -> QString;
    };
}
