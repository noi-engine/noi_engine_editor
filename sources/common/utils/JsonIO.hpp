//
// Created by ricka on 8/14/26.
//

#pragma once

#include <QJsonDocument>

namespace noi_engine_editor::JsonIO
{
    [[nodiscard]] auto read(const QString& path) -> QJsonDocument;
    auto write(const QString& path, const QJsonDocument& doc) -> void;
}
