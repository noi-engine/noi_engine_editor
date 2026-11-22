//
// Created by ricka on 8/14/26.
//

#include "JsonIO.hpp"
#include <QFile>
#include <QSaveFile>
#include <stdexcept>

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
    // QSaveFile writes to a temporary file and renames it on commit, so a crash or a full disk
    // can't leave a truncated project / settings file behind.
    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly) || file.write(doc.toJson()) < 0 || !file.commit())
    {
        throw std::runtime_error(("Could not write file " + path + ": " + file.errorString()).toStdString());
    }
}
