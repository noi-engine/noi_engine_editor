#include "EditorLogger.hpp"

#include <QMetaObject>
#include <QMutexLocker>

noi_engine_editor::EditorLogger::EditorLogger(QObject* parent) : QObject(parent)
{
    const QMutexLocker locker(&s_mutex);
    s_instance = this;
    m_text = s_buffer;
}

auto noi_engine_editor::EditorLogger::install() -> void
{
    s_previousHandler = qInstallMessageHandler(&EditorLogger::messageHandler);
}

auto noi_engine_editor::EditorLogger::text() const -> QString
{
    return m_text;
}

auto noi_engine_editor::EditorLogger::clear() -> void
{
    {
        const QMutexLocker locker(&s_mutex);
        s_buffer.clear();
    }

    m_text.clear();
    emit textChanged();
}

auto noi_engine_editor::EditorLogger::messageHandler(
    const QtMsgType type, const QMessageLogContext& context, const QString& message) -> void
{
    if (s_previousHandler)
    {
        s_previousHandler(type, context, message);
    }

    const char* label = "LOG";
    switch (type)
    {
        case QtDebugMsg:
            label = "DEBUG";
            break;
        case QtInfoMsg:
            label = "INFO";
            break;
        case QtWarningMsg:
            label = "WARNING";
            break;
        case QtCriticalMsg:
            label = "CRITICAL";
            break;
        case QtFatalMsg:
            label = "FATAL";
            break;
    }

    appendLine(QStringLiteral("[%1] %2").arg(QString::fromLatin1(label), message));
}

auto noi_engine_editor::EditorLogger::appendLine(const QString& line) -> void
{
    const QMutexLocker locker(&s_mutex);
    s_buffer += line + QLatin1Char('\n');

    if (s_instance)
    {
        QMetaObject::invokeMethod(
            s_instance,
            [instance = s_instance, line]()
            {
                instance->m_text += line + QLatin1Char('\n');
                emit instance->textChanged();
            },
            Qt::QueuedConnection);
    }
}
