//
// Created by ricka on 8/14/26.
//

#pragma once

#include <QJsonDocument>

namespace noi_engine_editor::JsonIO
{
    [[nodiscard]] auto read(const QString& path) -> QJsonDocument;
    // Throws std::runtime_error when the file can't be written.
    auto write(const QString& path, const QJsonDocument& doc) -> void;
}
