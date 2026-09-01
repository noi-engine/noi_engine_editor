#pragma once

#include <QMutex>
#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QtLogging>

namespace noi_engine_editor
{
    class EditorLogger : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

        Q_PROPERTY(QString text READ text NOTIFY textChanged)

    public:
        explicit EditorLogger(QObject* parent = nullptr);

        static auto install() -> void;

        Q_INVOKABLE auto clear() -> void;

        [[nodiscard]] auto text() const -> QString;

    signals:
        void textChanged();

    private:
        static auto messageHandler(QtMsgType type, const QMessageLogContext& context, const QString& message)
            -> void;
        static auto appendLine(const QString& line) -> void;

        inline static QMutex s_mutex;
        inline static QString s_buffer;
        inline static QtMessageHandler s_previousHandler = nullptr;
        inline static EditorLogger* s_instance = nullptr;

        QString m_text;
    };
}
