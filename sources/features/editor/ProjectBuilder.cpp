#include "ProjectBuilder.hpp"

#include <QDir>
#include <QFile>
#include <QProcess>
#include <memory>

noi_engine_editor::ProjectBuilder::ProjectBuilder(QObject* parent) : QObject(parent)
{
}

noi_engine_editor::ProjectBuilder::~ProjectBuilder()
{
    // Closing the editor mid-build must not leave cmake running in the background.
    if (m_process != nullptr)
    {
        m_process->disconnect(this);
        m_process->kill();
        m_process->waitForFinished(2000);
    }
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
    if (m_isCompiling || projectPath.isEmpty())
    {
        return;
    }

    clearOutput();
    setCompiling(true);
    runSteps(projectPath, presetSteps(QStringLiteral("debug")), [this](const bool success)
    {
        if (success)
        {
            ++m_compileGeneration;
            emit compileGenerationChanged();
        }
        setLastCompileFailed(!success);
        setCompiling(false);
        emit compileFinished(success);
    });
}

auto noi_engine_editor::ProjectBuilder::compileRelease(const QString& projectPath) -> void
{
    if (m_isCompiling || projectPath.isEmpty())
    {
        return;
    }

    clearOutput();
    setCompiling(true);

    const auto buildDir = QDir(projectPath).filePath(QStringLiteral("build/release"));
    runSteps(projectPath, presetSteps(QStringLiteral("release")), [this, projectPath, buildDir](const bool built)
    {
        if (!built)
        {
            setCompiling(false);
            emit releaseFinished(false, {});
            return;
        }

        // Projects made from an up-to-date template define a CPack package (the game folder,
        // zipped). Older ones only have the raw build output.
        const auto packagesDir = QDir(buildDir).filePath(QStringLiteral("packages"));
        const auto canPackage = QFile::exists(QDir(buildDir).filePath(QStringLiteral("CPackConfig.cmake")));
        if (!canPackage)
        {
            const auto outputPath = QDir(buildDir).filePath(QStringLiteral("bin"));
            appendOutput(QStringLiteral("\nRelease build ready in %1\n"
                                        "(this project has no packaging setup: update it from the latest template to get an "
                                        "installable archive)\n").arg(outputPath));
            setCompiling(false);
            emit releaseFinished(true, outputPath);
            return;
        }

        const QList<Step> packageSteps{
            {QStringLiteral("cmake"), {"--build", "--preset", "release", "--target", "package"}},
        };
        runSteps(projectPath, packageSteps, [this, packagesDir](const bool packaged)
        {
            if (packaged)
            {
                appendOutput(QStringLiteral("\nGame package ready in %1\n").arg(packagesDir));
            }
            setCompiling(false);
            emit releaseFinished(packaged, packagesDir);
        });
    });
}

auto noi_engine_editor::ProjectBuilder::presetSteps(const QString& preset) -> QList<Step>
{
    return {
        {QStringLiteral("cmake"), {"--preset", preset}},
        {QStringLiteral("cmake"), {"--build", "--preset", preset}},
    };
}

// Runs the steps one after the other, streaming their output to output(). Stops at the first
// failing step. A program that can't even start (cmake not installed) counts as a failure, so
// the "compiling" state can never be left on.
auto noi_engine_editor::ProjectBuilder::runSteps(const QString& projectPath, const QList<Step>& steps,
                                                 const std::function<void(bool)>& onFinished, const int index) -> void
{
    if (index >= steps.size())
    {
        appendOutput(QStringLiteral("\nBuild succeeded.\n"));
        onFinished(true);
        return;
    }

    const auto& step = steps[index];
    appendOutput(QStringLiteral("%1$ %2 %3\n").arg(index == 0 ? QString() : QStringLiteral("\n"), step.program,
                                                    step.arguments.join(' ')));

    auto* process = new QProcess(this);
    m_process = process;
    process->setWorkingDirectory(projectPath);
    process->setProcessChannelMode(QProcess::MergedChannels);

    // finished and errorOccurred can both fire for one process; only the first one counts.
    const auto settled = std::make_shared<bool>(false);
    const auto settle = [this, process, settled, onFinished](const bool ok, const QString& failure)
    {
        if (*settled)
        {
            return;
        }
        *settled = true;
        if (m_process == process)
        {
            m_process = nullptr;
        }
        process->deleteLater();

        if (!ok)
        {
            appendOutput(failure);
            onFinished(false);
        }
    };

    connect(process, &QProcess::readyReadStandardOutput, this,
            [this, process]() { appendOutput(QString::fromUtf8(process->readAllStandardOutput())); });

    connect(process, &QProcess::errorOccurred, this,
            [process, step, settle](const QProcess::ProcessError error)
            {
                if (error == QProcess::FailedToStart)
                {
                    settle(false, QStringLiteral("\nCan't run '%1' (%2). Is it installed and in your PATH?\n")
                                      .arg(step.program, process->errorString()));
                }
            });

    connect(process, &QProcess::finished, this,
            [this, projectPath, steps, onFinished, index, process, settle](const int exitCode,
                                                                           const QProcess::ExitStatus status)
            {
                appendOutput(QString::fromUtf8(process->readAllStandardOutput()));

                if (exitCode != 0 || status != QProcess::NormalExit)
                {
                    settle(false, QStringLiteral("\n%1 failed.\n").arg(steps[index].arguments.contains("--build")
                                                                              ? QStringLiteral("Build")
                                                                              : QStringLiteral("Configure")));
                    return;
                }

                settle(true, {});
                // The next step starts after this process is released.
                runSteps(projectPath, steps, onFinished, index + 1);
            });

    process->start(step.program, step.arguments);
}
