#include "ZipExtractor.hpp"

#include <QDir>
#include <QDebug>
#include <zip.h>

namespace noi_engine::zip_utils
{
    auto unzip(const QString& zipFilePath, const QString& destinationDir) -> bool
    {
        if (const QDir dir(destinationDir); !dir.exists())
        {
            if (!dir.mkpath("."))
            {
                qWarning() << "Failed to create destination directory:" << destinationDir;
                return false;
            }
        }

        const auto result = zip_extract(
            zipFilePath.toUtf8().constData(),
            destinationDir.toUtf8().constData(),
            nullptr,
            nullptr
        );

        return result == 0;
    }
}
