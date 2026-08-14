//
// Created by ricka on 8/14/26.
//

#pragma once

#include <QJsonObject>

namespace noi_engine_editor::Json
{
    template <typename T>
    concept JsonSerializable = requires(const T& value, const QJsonObject& object)
    {
        { value.serialize() } -> std::same_as<QJsonObject>;
        { T::deserialize(object) } -> std::same_as<T>;
    };

    template <JsonSerializable T>
    auto serialize(const T& value) -> QJsonObject
    {
        return value.serialize();
    }

    template <JsonSerializable T>
    auto deserialize(const QJsonObject& object) -> T
    {
        return T::deserialize(object);
    }
}
