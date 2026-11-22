#include "SettingsManager.hpp"

#include <QDir>
#include <QSettings>
#include <QStandardPaths>
#include "../../common/utils/PathResolver.hpp"

namespace noi_engine_editor
{
    namespace
    {
        constexpr auto DEFAULT_PROJECTS_PATH_KEY = "defaultProjectsPath";
        constexpr auto CODE_EDITOR_COMMAND_KEY = "codeEditorCommand";
    }

    SettingsManager::SettingsManager(QObject* parent) : QObject(parent)
    {
        const QSettings settings;
        const auto fallback = PathResolver::fallBackDefaultProjectsPath();

        m_defaultProjectsPath = settings.value(DEFAULT_PROJECTS_PATH_KEY, fallback).toString();
        m_codeEditorCommand = settings.value(CODE_EDITOR_COMMAND_KEY).toString();
    }

    auto SettingsManager::defaultProjectsPath() const -> QString
    {
        return m_defaultProjectsPath;
    }

    auto SettingsManager::setDefaultProjectsPath(const QString& path) -> void
    {
        if (m_defaultProjectsPath == path)
        {
            return;
        }

        m_defaultProjectsPath = path;

        QSettings settings;
        settings.setValue(DEFAULT_PROJECTS_PATH_KEY, path);

        emit defaultProjectsPathChanged();
    }

    auto SettingsManager::codeEditorCommand() const -> QString
    {
        return m_codeEditorCommand;
    }

    auto SettingsManager::setCodeEditorCommand(const QString& command) -> void
    {
        if (m_codeEditorCommand == command)
        {
            return;
        }

        m_codeEditorCommand = command;

        QSettings settings;
        settings.setValue(CODE_EDITOR_COMMAND_KEY, command);

        emit codeEditorCommandChanged();
    }
}
