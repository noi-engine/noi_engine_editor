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

    auto extractZipData(const QString& targetPath, const QByteArray& zipData, const char* logTag) -> bool;

    auto removeDirectory(const QString& targetPath, const char* logTag) -> void;
}
