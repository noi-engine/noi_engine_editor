#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>

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

    public:
        explicit ProjectBuilder(QObject* parent = nullptr);

        Q_INVOKABLE auto compile(const QString& projectPath) -> void;
        Q_INVOKABLE auto clearOutput() -> void;

        [[nodiscard]] auto isCompiling() const -> bool;
        [[nodiscard]] auto output() const -> QString;
        [[nodiscard]] auto compileGeneration() const -> int;

    signals:
        void isCompilingChanged();
        void outputChanged();
        void compileGenerationChanged();
        void compileFinished(bool success);

    private:
        bool m_isCompiling{false};
        QString m_output;
        int m_compileGeneration{0};

        auto setCompiling(bool compiling) -> void;
        auto appendOutput(const QString& text) -> void;
    };
}
