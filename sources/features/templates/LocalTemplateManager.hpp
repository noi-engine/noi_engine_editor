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
        Q_PROPERTY(QString downloadingTemplateId READ downloadingTemplateId NOTIFY isDownloadingChanged)

    public:
        explicit LocalTemplateManager(QObject* parent = nullptr);
        ~LocalTemplateManager() override = default;

        [[nodiscard]] auto templates() const -> QVariantList;
        [[nodiscard]] auto isDownloading() const -> bool;
        [[nodiscard]] auto downloadingTemplateId() const -> QString;

        Q_INVOKABLE [[nodiscard]] auto installedVersions(const QString& templateId) const -> QVariantList;
        Q_INVOKABLE [[nodiscard]] auto latestInstalledVersion(const QString& templateId) const -> QString;
        Q_INVOKABLE auto loadLocalTemplates() -> void;
        Q_INVOKABLE auto downloadTemplate(const QString& templateId, const QString& version, const QString& repositoryUrl) -> void;
        Q_INVOKABLE auto removeTemplateVersion(const QString& templateId, const QString& version) -> void;

    signals:
        auto templatesChanged() -> void;
        auto isDownloadingChanged() -> void;
        auto downloadFinished(const QString& templateId, bool success) -> void;

    private:
        QVariantList m_templates;
        QNetworkAccessManager m_networkManager;
        bool m_isDownloading{false};
        QString m_downloadingTemplateId;
    };
}
