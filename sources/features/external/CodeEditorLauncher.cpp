#include "CodeEditorLauncher.hpp"

#include "../settings/SettingsManager.hpp"

#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QSettings>
#include <QStandardPaths>
#include <QUrl>

namespace
{
    // In the order they are tried.
    const QStringList KNOWN_EDITORS{"code", "codium", "vscodium", "cursor", "zed", "clion", "qtcreator", "kate", "subl", "gedit", "xed"};

    auto configuredCommand() -> QStringList
    {
        const QSettings settings;
        return QProcess::splitCommand(settings.value("codeEditorCommand").toString().trimmed());
    }

    auto detectedProgram() -> QString
    {
        for (const auto& name : KNOWN_EDITORS)
        {
            if (!QStandardPaths::findExecutable(name).isEmpty())
            {
                return name;
            }
        }
        return {};
    }
}

namespace noi_engine_editor
{
    CodeEditorLauncher::CodeEditorLauncher(QObject* parent) : QObject(parent)
    {
    }

    auto CodeEditorLauncher::detectedEditor() const -> QString
    {
        if (const auto command = configuredCommand(); !command.isEmpty())
        {
            return command.first();
        }
        return detectedProgram();
    }

    auto CodeEditorLauncher::scriptFile(const QString& projectPath, const QString& scriptName) const -> QString
    {
        const QDir scripts(QDir(projectPath).filePath("sources/scripts"));
        for (const auto& extension : {QStringLiteral(".cpp"), QStringLiteral(".hpp"), QStringLiteral(".h")})
        {
            if (const auto candidate = scripts.filePath(scriptName + extension); QFileInfo::exists(candidate))
            {
                return candidate;
            }
        }
        return {};
    }

    auto CodeEditorLauncher::open(const QString& projectPath, const QString& filePath) -> bool
    {
        auto command = configuredCommand();
        if (command.isEmpty())
        {
            if (const auto program = detectedProgram(); !program.isEmpty())
            {
                command = {program};
            }
        }

        if (!command.isEmpty())
        {
            const auto program = command.takeFirst();
            // Folder first, then the file: editors open the folder and show that file in it.
            QStringList arguments = command;
            arguments << projectPath;
            if (!filePath.isEmpty())
            {
                arguments << filePath;
            }
            // Detached, and its console output (VS Code and other Electron editors print a lot of
            // start-up warnings) goes nowhere instead of into the editor's own log.
            QProcess process;
            process.setProgram(program);
            process.setArguments(arguments);
            process.setStandardOutputFile(QProcess::nullDevice());
            process.setStandardErrorFile(QProcess::nullDevice());
            if (process.startDetached())
            {
                return true;
            }
        }

        // No known editor: the system's choice for that file or folder.
        return QDesktopServices::openUrl(QUrl::fromLocalFile(filePath.isEmpty() ? projectPath : filePath));
    }
}
