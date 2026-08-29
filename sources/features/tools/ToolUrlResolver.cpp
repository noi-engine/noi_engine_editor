#include "ToolUrlResolver.hpp"

#include <QSysInfo>

namespace
{
    auto currentPlatformOsName() -> QString
    {
        const auto kernelType = QSysInfo::kernelType();
        if (kernelType == "darwin") return "macos";
        if (kernelType == "winnt") return "windows";
        return "linux";
    }

    auto currentPlatformArchName() -> QString
    {
        const auto arch = QSysInfo::currentCpuArchitecture();
        if (arch == "x86_64") return "x64";
        return arch;
    }
}

auto noi_engine_editor::ToolUrlResolver::releaseApiUrl(
    const QString& owner,
    const QString& repository,
    const QString& version
) -> QString
{
    if (version.isEmpty() || version == "latest")
    {
        return QString("https://api.github.com/repos/%1/%2/releases/latest").arg(owner, repository);
    }

    return QString("https://api.github.com/repos/%1/%2/releases/tags/%3").arg(owner, repository, version);
}

auto noi_engine_editor::ToolUrlResolver::noiEngineReleaseApiUrl(const QString& version) -> QString
{
    return releaseApiUrl("noi-engine", "noi_engine", version);
}

auto noi_engine_editor::ToolUrlResolver::resourceCompilerReleaseApiUrl(const QString& version) -> QString
{
    return releaseApiUrl("noi-engine", "resources_compiler", version);
}

auto noi_engine_editor::ToolUrlResolver::currentPlatformNoiEngineAssetName() -> QString
{
    return QString("noi_engine-%1-%2-release.zip").arg(currentPlatformOsName(), currentPlatformArchName());
}

auto noi_engine_editor::ToolUrlResolver::resourceCompilerAssetName() -> QString
{
    return "resources_compiler.zip";
}
