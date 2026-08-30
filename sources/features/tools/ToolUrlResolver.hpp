#pragma once

#include <QString>

namespace noi_engine_editor::ToolUrlResolver
{
    [[nodiscard]] auto noiEngineDownloadUrl(const QString& version) -> QString;
    [[nodiscard]] auto resourceCompilerDownloadUrl(const QString& version) -> QString;

    [[nodiscard]] auto currentPlatformNoiEngineAssetName() -> QString;
    [[nodiscard]] auto resourceCompilerAssetName() -> QString;
}
