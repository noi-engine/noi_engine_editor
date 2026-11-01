#include "EditorBridgeResolver.hpp"
#include "JsonIO.hpp"
#include "PathResolver.hpp"

#include <QDir>
#include <QJsonObject>
#include <QStringList>
#include <noi_engine_editor_bridge/bridge_api.h>

namespace noi_engine_editor
{
    auto EditorBridgeResolver::compareVersions(const QString& a, const QString& b) -> int
    {
        const auto partsA = a.split('.');
        const auto partsB = b.split('.');
        const auto count = std::max(partsA.size(), partsB.size());

        for (qsizetype i = 0; i < count; ++i)
        {
            const auto valueA = i < partsA.size() ? partsA[i].toInt() : 0;
            const auto valueB = i < partsB.size() ? partsB[i].toInt() : 0;
            if (valueA != valueB)
            {
                return valueA < valueB ? -1 : 1;
            }
        }
        return 0;
    }

    auto EditorBridgeResolver::resolve(const QString& bridgeVersion, const QString& engineVersion) -> Resolution
    {
        if (bridgeVersion.isEmpty())
        {
            return {.error = QObject::tr("This project was made for an older version of the editor (it has no "
                                         "editor_bridge_version). Create a new project from an up-to-date template.")};
        }

        const auto contentPath = PathResolver::editorBridgeContentPath(bridgeVersion);
        QJsonObject manifest;
        try
        {
            manifest = JsonIO::read(QDir(contentPath).filePath("bridge.json")).object();
        }
        catch (const std::exception&)
        {
            return {.error = QObject::tr("This project needs the editor bridge v%1, which isn't downloaded yet")
                                 .arg(bridgeVersion),
                    .notInstalled = true};
        }

        if (const auto apiVersion = manifest.value("api_version").toInt(); apiVersion != NOI_ENGINE_EDITOR_BRIDGE_API_VERSION)
        {
            return {.error = QObject::tr("Editor bridge v%1 uses API v%2, this editor needs API v%3")
                                 .arg(bridgeVersion).arg(apiVersion).arg(NOI_ENGINE_EDITOR_BRIDGE_API_VERSION)};
        }

        const auto engineRange = manifest.value("noi_engine").toObject();
        const auto minEngine = engineRange.value("min").toString();
        const auto maxEngine = engineRange.value("max").toString();

        if (compareVersions(engineVersion, minEngine) < 0 || compareVersions(engineVersion, maxEngine) > 0)
        {
            return {.error = QObject::tr("Editor bridge v%1 supports noi_engine %2 to %3, the project uses %4")
                                 .arg(bridgeVersion, minEngine, maxEngine, engineVersion)};
        }

        // QLibrary adds the platform prefix/suffix (libnoi_engine_editor_bridge.so / .dylib).
        return {.libraryPath = QDir(contentPath).filePath("libs/noi_engine_editor_bridge")};
    }
}
