#include "Version.hpp"

#include <QStringList>

#include <algorithm>

auto noi_engine_editor::Version::compare(const QString& lhs, const QString& rhs) -> int
{
    const auto lhsParts = lhs.split('.');
    const auto rhsParts = rhs.split('.');
    const auto count = std::max(lhsParts.size(), rhsParts.size());

    for (qsizetype i = 0; i < count; ++i)
    {
        const auto lhsPart = i < lhsParts.size() ? lhsParts[i] : QStringLiteral("0");
        const auto rhsPart = i < rhsParts.size() ? rhsParts[i] : QStringLiteral("0");

        bool lhsIsNumber = false;
        bool rhsIsNumber = false;
        const auto lhsNumber = lhsPart.toLongLong(&lhsIsNumber);
        const auto rhsNumber = rhsPart.toLongLong(&rhsIsNumber);

        if (lhsIsNumber && rhsIsNumber)
        {
            if (lhsNumber != rhsNumber)
            {
                return lhsNumber < rhsNumber ? -1 : 1;
            }
        }
        else if (const auto cmp = lhsPart.compare(rhsPart); cmp != 0)
        {
            return cmp < 0 ? -1 : 1;
        }
    }

    return 0;
}
