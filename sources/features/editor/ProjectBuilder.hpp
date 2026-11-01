#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <functional>

namespace noi_engine_editor
{
    class ProjectBuilder : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

        Q_PROPERTY(bool isCompiling READ isCompiling NOTIFY isCompilingChanged)
        Q_PROPERTY(QString output READ output NOTIFY outputChanged)
        Q_PROPERTY(int compileGeneration READ compileGeneration NOTIFY compileGenerationChanged)
        Q_PROPERTY(bool lastCompileFailed READ lastCompileFailed NOTIFY lastCompileFailedChanged)
        Q_PROPERTY(bool hasCompiledOnce READ hasCompiledOnce NOTIFY hasCompiledOnceChanged)

    public:
        explicit ProjectBuilder(QObject* parent = nullptr);

        // Debug build: the one the viewport runs (scripts library), bumps compileGeneration.
        Q_INVOKABLE auto compile(const QString& projectPath) -> void;
        // Release build of the game (compiled resources) in build/release/bin. Doesn't touch the
        // debug build's state.
        Q_INVOKABLE auto compileRelease(const QString& projectPath) -> void;
        Q_INVOKABLE auto clearOutput() -> void;

        [[nodiscard]] auto isCompiling() const -> bool;
        [[nodiscard]] auto output() const -> QString;
        [[nodiscard]] auto compileGeneration() const -> int;
        [[nodiscard]] auto lastCompileFailed() const -> bool;
        [[nodiscard]] auto hasCompiledOnce() const -> bool;

    signals:
        void isCompilingChanged();
        void outputChanged();
        void compileGenerationChanged();
        void lastCompileFailedChanged();
        void hasCompiledOnceChanged();
        void compileFinished(bool success);
        void releaseFinished(bool success, const QString& outputPath);

    private:
        bool m_isCompiling{false};
        QString m_output;
        int m_compileGeneration{0};
        bool m_lastCompileFailed{false};
        bool m_hasCompiledOnce{false};

        auto setCompiling(bool compiling) -> void;
        auto setLastCompileFailed(bool failed) -> void;
        auto appendOutput(const QString& text) -> void;
        auto build(const QString& projectPath, const QString& preset, const std::function<void(bool)>& onFinished) -> void;
    };
}
