#include "ProjectCreator.hpp"

#include <QDir>
#include <QJsonObject>
#include <Templi/Templi.hpp>
#include "../../common/utils/PathResolver.hpp"

namespace noi_engine_editor
{
    ProjectCreator::ProjectCreator(QObject* parent) : QObject(parent)
    {
    }

    auto ProjectCreator::createProject(
        const QString& name,
        const QString& location,
        const QString& templateId,
        const QString& templateVersion,
        const QString& engineVersion,
        const QString& resourceCompilerVersion,
        const QString& editorBridgeVersion
    ) -> bool
    {
        const auto trimmedName = name.trimmed();
        if (trimmedName.isEmpty() || trimmedName == QStringLiteral(".") || trimmedName == QStringLiteral("..")
            || trimmedName.contains('/') || trimmedName.contains('\\'))
        {
            emit projectCreationFailed(tr("Invalid project name (no slashes, and not empty)"));
            return false;
        }

        const auto projectPath = QDir(location).filePath(trimmedName);
        if (const QDir root(projectPath); root.exists())
        {
            emit projectCreationFailed(tr("A folder with this name already exists"));
            return false;
        }

        try
        {
            const auto templatePath = PathResolver::templateAbsolutePath(templateId, templateVersion);
            QDir().mkpath(location);
            Templi::generate_with_templi_config(
                templatePath.toStdString(),
                projectPath.toStdString(),
                [trimmedName, engineVersion, resourceCompilerVersion, editorBridgeVersion](const Templi::Placeholder& placeholder) -> std::string
                {
                    if (placeholder.m_name == "PROJECT_NAME") return trimmedName.toStdString();
                    if (placeholder.m_name == "PROJECT_VERSION") return "0.0.1";
                    if (placeholder.m_name == "PROJECT_CATEGORY") return "2D";
                    if (placeholder.m_name == "ENGINE_VERSION") return engineVersion.toStdString();
                    if (placeholder.m_name == "RESOURCES_COMPILER_VERSION") return resourceCompilerVersion.toStdString();
                    if (placeholder.m_name == "EDITOR_BRIDGE_VERSION") return editorBridgeVersion.toStdString();
                    return "";
                }
            );

            const auto enginePath = PathResolver::noiEngineContentPath(engineVersion);
            std::filesystem::copy(
                enginePath.toStdString(),
                QDir(projectPath).filePath(".noi_engine").toStdString(),
                std::filesystem::copy_options::recursive |
                std::filesystem::copy_options::overwrite_existing
            );

            // The editor bridge is editor-only: it stays in the editor's tools folder and is never
            // copied into the project.
            const auto resourcesCompilerPath = PathResolver::resourceCompilerContentPath(resourceCompilerVersion);
            std::filesystem::copy(
                resourcesCompilerPath.toStdString(),
                QDir(projectPath).filePath(".resources_compiler").toStdString(),
                std::filesystem::copy_options::recursive |
                std::filesystem::copy_options::overwrite_existing
            );
        }
        catch (const std::exception& exception)
        {
            QDir(projectPath).removeRecursively();
            emit projectCreationFailed(QString::fromUtf8(exception.what()));
            return false;
        }
        catch (...)
        {
            QDir(projectPath).removeRecursively();
            emit projectCreationFailed(tr("Unknown error while creating the project"));
            return false;
        }

        emit projectCreated(trimmedName, projectPath);
        return true;
    }
}
