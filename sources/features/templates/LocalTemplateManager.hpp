#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QVariantList>

namespace noi_engine_editor
{
    class LocalTemplateManager : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
        Q_PROPERTY(QVariantList templates READ templates NOTIFY templatesChanged)

    public:
        explicit LocalTemplateManager(QObject* parent = nullptr);
        ~LocalTemplateManager() override = default;

        [[nodiscard]] auto templates() const -> QVariantList;

        Q_INVOKABLE auto loadLocalTemplates() -> void;

    signals:
        auto templatesChanged() -> void;

    private:
        QVariantList m_templates;
    };
}