#pragma once

#include <QByteArray>
#include <QNetworkAccessManager>
#include <QString>
#include <functional>

// Download/extract/cleanup steps shared by TemplateInstaller and ToolInstaller.
// `logTag` prefixes warnings, e.g. "[ToolInstaller]".
namespace noi_engine_editor::zip_install
{
    auto downloadZip(
        QNetworkAccessManager& networkManager,
        const QString& downloadUrl,
        const char* logTag,
        const std::function<void(const QByteArray& zipData)>& onSuccess,
        const std::function<void()>& onError
    ) -> void;

    // Extracts into `targetPath`, which is created if needed.
    auto extractZipData(const QString& targetPath, const QByteArray& zipData, const char* logTag) -> bool;

    // Extracts into a staging folder next to `targetPath`, runs `postProcess` on it (may be empty),
    // then swaps it in place of `targetPath`. On any failure the staging folder is removed and an
    // existing `targetPath` (a previous, working install) is left untouched.
    auto installZipData(
        const QString& targetPath,
        const QByteArray& zipData,
        const char* logTag,
        const std::function<bool(const QString& stagingPath)>& postProcess = {}
    ) -> bool;

    auto removeDirectory(const QString& targetPath, const char* logTag) -> void;
}
