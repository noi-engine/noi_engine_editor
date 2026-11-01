#include "ProjectBuilder.hpp"

#include <QDir>
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

auto noi_engine_editor::ProjectBuilder::lastCompileFailed() const -> bool
{
    return m_lastCompileFailed;
}

auto noi_engine_editor::ProjectBuilder::hasCompiledOnce() const -> bool
{
    return m_hasCompiledOnce;
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

auto noi_engine_editor::ProjectBuilder::setLastCompileFailed(const bool failed) -> void
{
    if (m_lastCompileFailed != failed)
    {
        m_lastCompileFailed = failed;
        emit lastCompileFailedChanged();
    }

    if (!m_hasCompiledOnce)
    {
        m_hasCompiledOnce = true;
        emit hasCompiledOnceChanged();
    }
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
    build(projectPath, QStringLiteral("debug"), [this](const bool success)
    {
        if (success)
        {
            ++m_compileGeneration;
            emit compileGenerationChanged();
        }
        setLastCompileFailed(!success);
        emit compileFinished(success);
    });
}

auto noi_engine_editor::ProjectBuilder::compileRelease(const QString& projectPath) -> void
{
    build(projectPath, QStringLiteral("release"), [this, projectPath](const bool success)
    {
        const auto outputPath = QDir(projectPath).filePath(QStringLiteral("build/release/bin"));
        if (success)
        {
            appendOutput(QStringLiteral("Release build ready in %1\n").arg(outputPath));
        }
        emit releaseFinished(success, outputPath);
    });
}

// cmake --preset <preset> then cmake --build --preset <preset>, output streamed to output().
auto noi_engine_editor::ProjectBuilder::build(const QString& projectPath, const QString& preset,
                                              const std::function<void(bool)>& onFinished) -> void
{
    if (m_isCompiling || projectPath.isEmpty())
    {
        return;
    }

    clearOutput();
    setCompiling(true);
    appendOutput(QStringLiteral("$ cmake --preset %1\n").arg(preset));

    auto* configure = new QProcess(this);
    configure->setWorkingDirectory(projectPath);
    configure->setProcessChannelMode(QProcess::MergedChannels);
    configure->setProgram("cmake");
    configure->setArguments({"--preset", preset});

    connect(configure, &QProcess::readyReadStandardOutput, this,
            [this, configure]() { appendOutput(QString::fromUtf8(configure->readAllStandardOutput())); });

    connect(configure, &QProcess::finished, this,
            [this, projectPath, preset, onFinished, configure](const int exitCode, const QProcess::ExitStatus status)
            {
                configure->deleteLater();

                if (exitCode != 0 || status != QProcess::NormalExit)
                {
                    appendOutput(QStringLiteral("\nConfigure failed.\n"));
                    setCompiling(false);
                    onFinished(false);
                    return;
                }

                appendOutput(QStringLiteral("\n$ cmake --build --preset %1\n").arg(preset));

                auto* buildProcess = new QProcess(this);
                buildProcess->setWorkingDirectory(projectPath);
                buildProcess->setProcessChannelMode(QProcess::MergedChannels);
                buildProcess->setProgram("cmake");
                buildProcess->setArguments({"--build", "--preset", preset});

                connect(buildProcess, &QProcess::readyReadStandardOutput, this,
                        [this, buildProcess]() { appendOutput(QString::fromUtf8(buildProcess->readAllStandardOutput())); });

                connect(buildProcess, &QProcess::finished, this,
                        [this, onFinished, buildProcess](const int buildExitCode, const QProcess::ExitStatus buildStatus)
                        {
                            const auto success = buildExitCode == 0 && buildStatus == QProcess::NormalExit;
                            appendOutput(success ? QStringLiteral("\nBuild succeeded.\n")
                                                 : QStringLiteral("\nBuild failed.\n"));
                            buildProcess->deleteLater();
                            setCompiling(false);
                            onFinished(success);
                        });

                buildProcess->start();
            });

    configure->start();
}
