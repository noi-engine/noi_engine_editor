//
// Created by ricka on 8/14/26.
//

#include "JsonIO.hpp"
#include <QFile>

auto noi_engine_editor::JsonIO::read(const QString& path) -> QJsonDocument
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
    {
        throw std::runtime_error(("Could not open file " + path + ".").toStdString());
    }

    return QJsonDocument::fromJson(file.readAll());
}

auto noi_engine_editor::JsonIO::write(const QString& path, const QJsonDocument& doc) -> void
{
    if (QFile file(path); file.open(QIODevice::WriteOnly))
    {
        file.write(doc.toJson());
    }
}
