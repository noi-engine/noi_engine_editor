#pragma once

#include <QString>

namespace noi_engine_editor::zip_utils
{
    auto unzip(const QString& zipFilePath, const QString& destinationDir) -> bool;
}
