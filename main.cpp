#include <QDebug>
#include <cstdio>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QTimer>

#include "sources/common/utils/PathResolver.hpp"
#include "sources/features/editor/EditorLogger.hpp"

using namespace noi_engine_editor;

auto main(int argc, char* argv[]) -> int
{
    EditorLogger::install();

    const QGuiApplication app(argc, argv);

    app.setOrganizationName("noi_engine");
    app.setApplicationName("noi_engine_editor");

    try
    {
        PathResolver::init();
    }
    catch (const std::exception& e)
    {
        qCritical() << "[main] Can't prepare the editor's data folders:" << e.what();
        return EXIT_FAILURE;
    }

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() -> void { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("noi_engine_editor", "Main");

    // Development aid: `--screenshot out.png [--screenshot-delay ms]` saves the window and quits
    // (works headless: QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software).
    const auto arguments = QCoreApplication::arguments();
    if (const auto index = arguments.indexOf("--screenshot"); index >= 0 && index + 1 < arguments.size())
    {
        const auto path = arguments.at(index + 1);
        const auto delayIndex = arguments.indexOf("--screenshot-delay");
        const auto delay = delayIndex >= 0 && delayIndex + 1 < arguments.size() ? arguments.at(delayIndex + 1).toInt() : 2500;
        QTimer::singleShot(delay, &app, [&engine, path]() -> void
        {
            for (auto* object : engine.rootObjects())
            {
                if (auto* window = qobject_cast<QQuickWindow*>(object))
                {
                    fprintf(stderr, "[screenshot] %dx%d visible=%d exposed=%d roots=%d\n", window->width(), window->height(), window->isVisible(), window->isExposed(), int(engine.rootObjects().size()));
                    window->grabWindow().save(path);
                }
            }
            QCoreApplication::quit();
        });
    }

    return QGuiApplication::exec();
}
