#include "ToolInstaller.hpp"
#include "ZipInstall.hpp"

#include <QDebug>

namespace
{
    constexpr auto LOG_TAG = "[ToolInstaller]";
}

namespace noi_engine_editor
{
    ToolInstaller::ToolInstaller(QNetworkAccessManager& networkManager)
        : m_networkManager(networkManager)
    {
    }

    auto ToolInstaller::install(
        const QString& downloadUrl,
        const QString& targetPath,
        const std::function<void(bool success)>& onFinished
    ) -> void
    {
        zip_install::downloadZip(
            m_networkManager,
            downloadUrl,
            LOG_TAG,
            [targetPath, onFinished](const QByteArray& zipData)
            {
                const auto success = zip_install::extractZipData(targetPath, zipData, LOG_TAG);
                if (!success)
                {
                    qWarning() << LOG_TAG << "Extraction failed for target:" << targetPath;
                    zip_install::removeDirectory(targetPath, LOG_TAG);
                }
                onFinished(success);
            },
            [targetPath, onFinished]()
            {
                qWarning() << LOG_TAG << "Download failed for target:" << targetPath;
                zip_install::removeDirectory(targetPath, LOG_TAG);
                onFinished(false);
            }
        );
    }
}
