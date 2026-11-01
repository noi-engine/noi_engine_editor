#pragma once

#include <QString>

// Finds the installed editor bridge a project asks for and checks it can run that project.
// A bridge release declares, in its bridge.json, the C API version it implements and the range
// of noi_engine versions it supports.
namespace noi_engine_editor::EditorBridgeResolver
{
    struct Resolution
    {
        QString libraryPath; // empty when the bridge can't be used
        QString error;       // why, when libraryPath is empty
        bool notInstalled{}; // the only problem is that the bridge isn't downloaded yet
    };

    [[nodiscard]] auto resolve(const QString& bridgeVersion, const QString& engineVersion) -> Resolution;

    // Compares dotted numeric versions ("0.0.109"): negative, zero or positive like strcmp.
    [[nodiscard]] auto compareVersions(const QString& a, const QString& b) -> int;
}
