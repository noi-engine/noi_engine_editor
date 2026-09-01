#include "ProjectBuilder.hpp"

#include <QProcess>

noi_engine_editor::ProjectBuilder::ProjectBuilder(QObject* parent) : QObject(parent)
{
}

auto noi_engine_editor::ProjectBuilder::isCompiling() const -> bool
{
    return m_isCompiling;
}

auto noi_engine_editor::ProjectBuilder::output() const -> QString
{
    return m_output;
}

auto noi_engine_editor::ProjectBuilder::compileGeneration() const -> int
{
    return m_compileGeneration;
}

auto noi_engine_editor::ProjectBuilder::setCompiling(const bool compiling) -> void
{
    if (m_isCompiling == compiling)
    {
        return;
    }

    m_isCompiling = compiling;
    emit isCompilingChanged();
}

auto noi_engine_editor::ProjectBuilder::appendOutput(const QString& text) -> void
{
    if (text.isEmpty())
    {
        return;
    }

    m_output += text;
    emit outputChanged();
}

auto noi_engine_editor::ProjectBuilder::clearOutput() -> void
{
    if (m_output.isEmpty())
    {
        return;
    }

    m_output.clear();
    emit outputChanged();
}

auto noi_engine_editor::ProjectBuilder::compile(const QString& projectPath) -> void
{
    if (m_isCompiling)
    {
        return;
    }

    if (projectPath.isEmpty())
    {
        return;
    }

    clearOutput();
    setCompiling(true);
    appendOutput(QStringLiteral("$ cmake --preset debug\n"));

    auto* configure = new QProcess(this);
    configure->setWorkingDirectory(projectPath);
    configure->setProcessChannelMode(QProcess::MergedChannels);
    configure->setProgram("cmake");
    configure->setArguments({ "--preset", "debug" });

    connect(configure, &QProcess::readyReadStandardOutput, this,
            [this, configure]() { appendOutput(QString::fromUtf8(configure->readAllStandardOutput())); });

    connect(configure, &QProcess::finished, this,
            [this, projectPath, configure](const int exitCode, const QProcess::ExitStatus status)
            {
                configure->deleteLater();

                if (exitCode != 0 || status != QProcess::NormalExit)
                {
                    appendOutput(QStringLiteral("\nConfigure failed.\n"));
                    setCompiling(false);
                    emit compileFinished(false);
                    return;
                }

                appendOutput(QStringLiteral("\n$ cmake --build --preset debug\n"));

                auto* build = new QProcess(this);
                build->setWorkingDirectory(projectPath);
                build->setProcessChannelMode(QProcess::MergedChannels);
                build->setProgram("cmake");
                build->setArguments({ "--build", "--preset", "debug" });

                connect(build, &QProcess::readyReadStandardOutput, this,
                        [this, build]() { appendOutput(QString::fromUtf8(build->readAllStandardOutput())); });

                connect(build, &QProcess::finished, this,
                        [this, build](const int buildExitCode, const QProcess::ExitStatus buildStatus)
                        {
                            const auto success = buildExitCode == 0 && buildStatus == QProcess::NormalExit;

                            appendOutput(success
                                             ? QStringLiteral("\nBuild succeeded.\n")
                                             : QStringLiteral("\nBuild failed.\n"));

                            build->deleteLater();

                            if (success)
                            {
                                ++m_compileGeneration;
                                emit compileGenerationChanged();
                            }

                            setCompiling(false);
                            emit compileFinished(success);
                        });

                build->start();
            });

    configure->start();
}
