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
        const QString& engineVersion,
        const QString& resourceCompilerVersion
    ) -> bool
    {
        const auto projectPath = QDir(location).filePath(name);
        if (const QDir root(projectPath); root.exists())
        {
            emit projectCreationFailed(tr("A folder with this name already exists"));
            return false;
        }

        try
        {
            const auto templatePath = PathResolver::templateAbsolutePath(templateId);
            Templi::generate_with_templi_config(
                templatePath.toStdString(),
                projectPath.toStdString(),
                [name](const Templi::Placeholder& placeholder) -> std::string
                {
                    if (placeholder.m_name == "PROJECT_NAME") return name.toStdString();
                    if (placeholder.m_name == "PROJECT_VERSION") return "0.0.1";
                    if (placeholder.m_name == "PROJECT_CATEGORY") return "2D";
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

            const auto resourcesCompilerPath = PathResolver::resourceCompilerPath(resourceCompilerVersion);
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

            emit projectCreationFailed(
                QString::fromUtf8(exception.what())
            );

            return false;
        }

        emit projectCreated(name, projectPath);
        return true;
    }
}
