#pragma once

#include <QQmlEngine>
#include <QVariantList>
#include <QNetworkAccessManager>

namespace noi_engine_editor
{
    class LocalTemplateManager : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
        Q_PROPERTY(QVariantList templates READ templates NOTIFY templatesChanged)
        Q_PROPERTY(bool isDownloading READ isDownloading NOTIFY isDownloadingChanged)

    public:
        explicit LocalTemplateManager(QObject* parent = nullptr);
        ~LocalTemplateManager() override = default;

        [[nodiscard]] auto templates() const -> QVariantList;
        [[nodiscard]] auto isDownloading() const -> bool;

        Q_INVOKABLE [[nodiscard]] auto isInstalled(const QString& templateId) const -> bool;
        Q_INVOKABLE auto loadLocalTemplates() -> void;
        Q_INVOKABLE auto downloadTemplate(const QString& templateId, const QString& repositoryUrl) -> void;

    signals:
        auto templatesChanged() -> void;
        auto isDownloadingChanged() -> void;
        auto downloadFinished(const QString& templateId, bool success) -> void;

    private:
        QVariantList m_templates;
        QNetworkAccessManager m_networkManager;
        bool m_isDownloading{false};
    };
}
