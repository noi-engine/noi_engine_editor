#pragma once

#include <QString>

namespace noi_engine_editor::ToolUrlResolver
{
    [[nodiscard]] auto releaseApiUrl(const QString& owner, const QString& repository, const QString& version) -> QString;
    [[nodiscard]] auto noiEngineReleaseApiUrl(const QString& version) -> QString;
    [[nodiscard]] auto resourceCompilerReleaseApiUrl(const QString& version) -> QString;

    [[nodiscard]] auto currentPlatformNoiEngineAssetName() -> QString;
    [[nodiscard]] auto resourceCompilerAssetName() -> QString;
}
