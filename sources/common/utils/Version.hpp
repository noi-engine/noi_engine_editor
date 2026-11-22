#pragma once

#include <QString>

namespace noi_engine_editor::Version
{
    // Compares dot-separated versions ("0.0.9" < "0.0.10"). Numeric segments compare as numbers,
    // anything else falls back to plain string comparison. Returns -1, 0 or 1.
    [[nodiscard]] auto compare(const QString& lhs, const QString& rhs) -> int;
}
