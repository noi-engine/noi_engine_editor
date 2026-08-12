#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QNetworkAccessManager>
#include <QNetworkReply>

namespace noi_engine_editor
{
    class TemplateManager : public QObject
    {
        Q_OBJECT
        Q_PROPERTY(QVariantList availableTemplates READ availableTemplates NOTIFY templatesChanged)
        Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

    public:
        explicit TemplateManager(QObject* parent = nullptr);

        Q_INVOKABLE void fetchCatalog(const QString& indexUrl);

        Q_INVOKABLE void downloadTemplate(const QString& templateId);

        Q_INVOKABLE bool isTemplateDownloaded(const QString& templateId) const;

        QVariantList availableTemplates() const { return m_templates; }

        bool isLoading() const { return m_isLoading; }

    signals:
        void templatesChanged();
        void isLoadingChanged();
        void downloadProgress(const QString& templateId, qint64 bytesReceived, qint64 bytesTotal);
        void downloadFinished(const QString& templateId, bool success, const QString& message);

    private:
        void fetchMetadataFromRepoUrl(const QString& repoUrl, int totalRepos);
        QString convertToRawJsonUrl(const QString& repoUrl) const;
        QString convertToZipUrl(const QString& repoUrl) const;
        QString templatesStoragePath() const;

        QNetworkAccessManager m_networkManager;
        QVariantList m_templates;
        bool m_isLoading = false;
        int m_pendingRequests = 0;
    };
}
