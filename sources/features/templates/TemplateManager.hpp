#pragma once

#include <QObject>
#include <QVariantList>
#include <QNetworkAccessManager>

namespace noi_engine_editor
{
    class TemplateManager : public QObject
    {
        Q_OBJECT
        Q_PROPERTY(bool isPending READ isPending NOTIFY isPendingChanged)
        Q_PROPERTY(QVariantList templates READ templates NOTIFY templatesChanged)

    public:
        explicit TemplateManager(QObject* parent = nullptr);
        ~TemplateManager() override = default;

        auto isPending() const -> bool;
        auto templates() const -> QVariantList;

        Q_INVOKABLE auto fetchTemplates() -> void;

    signals:
        auto isPendingChanged() -> void;
        auto templatesChanged() -> void;
        auto fetchFailed(const QString& error) -> void;

    private:
        auto fetchIndividualTemplate(const QString& repositoryUrl) -> void;
        auto checkCompletion() -> void;
        auto setPending(bool pending) -> void;

        QNetworkAccessManager m_networkManager;
        QVariantList m_templates;
        int m_pendingRequests = 0;
        bool m_isPending = false;
    };
}