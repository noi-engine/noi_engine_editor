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

    auto directDownloadUrl(
        const QString& owner,
        const QString& repository,
        const QString& version,
        const QString& assetName
    ) -> QString
    {
        const auto tag = version.startsWith("v") ? version : "v" + version;
        return QString("https://github.com/%1/%2/releases/download/%3/%4")
            .arg(owner, repository, tag, assetName);
    }
}

auto noi_engine_editor::ToolUrlResolver::noiEngineDownloadUrl(const QString& version) -> QString
{
    return directDownloadUrl(
        "noi-engine",
        "noi_engine_release",
        version,
        currentPlatformNoiEngineAssetName()
    );
}

auto noi_engine_editor::ToolUrlResolver::resourceCompilerDownloadUrl(const QString& version) -> QString
{
    return directDownloadUrl(
        "noi-engine",
        "resources_compiler",
        version,
        resourceCompilerAssetName()
    );
}

auto noi_engine_editor::ToolUrlResolver::currentPlatformNoiEngineAssetName() -> QString
{
    return QString("noi_engine-%1-%2-release.zip").arg(currentPlatformOsName(), currentPlatformArchName());
}

auto noi_engine_editor::ToolUrlResolver::resourceCompilerAssetName() -> QString
{
    return "resources_compiler.zip";
}
