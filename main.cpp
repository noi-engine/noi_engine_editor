#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include "sources/common/utils/PathResolver.hpp"

using namespace noi_engine_editor;

auto main(int argc, char* argv[]) -> int
{
    const QGuiApplication app(argc, argv);

    app.setOrganizationName("noi_engine");
    app.setApplicationName("noi_engine_editor");
    PathResolver::init();

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() -> void { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("noi_engine_editor", "Main");

    return QGuiApplication::exec();
}
