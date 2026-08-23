//
// Created by ricka on 8/23/26.
//

#pragma once

#include <QString>

namespace noi_engine::zip_utils
{
    auto unzip(const QString& zipFilePath, const QString& destinationDir) -> bool;
}