#include "TemplateManager.hpp"

#include "TemplateUrlResolver.hpp"

#include <QNetworkReply>
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>

namespace noi_engine_editor
{
    TemplateManager::TemplateManager(QObject* parent)
        : QObject(parent)
    {
    }

    auto TemplateManager::isPending() const -> bool
    {
        return m_isPending;
    }

    auto TemplateManager::templates() const -> QVariantList
    {
        return m_templates;
    }

    auto TemplateManager::setPending(bool pending) -> void
    {
        if (m_isPending != pending)
        {
            m_isPending = pending;
            emit isPendingChanged();
        }
    }

    auto TemplateManager::fetchTemplates() -> void
    {
        m_templates.clear();
        emit templatesChanged();

        m_pendingRequests = 0;
        setPending(true);

        const QUrl indexUrl(TemplateUrlResolver::templatesJsonUrl());
        QNetworkRequest request(indexUrl);
        request.setRawHeader("User-Agent", "noi_engine_editor");
        QNetworkReply* reply = m_networkManager.get(request);

        connect(reply, &QNetworkReply::finished, this, [this, reply, indexUrl]() -> void {
            reply->deleteLater();

            if (reply->error() != QNetworkReply::NoError)
            {
                qWarning() << "[TemplateManager] Failed to fetch template index from:" << indexUrl
                           << "| Error:" << reply->errorString();
                setPending(false);
                emit fetchFailed(reply->errorString());
                return;
            }

            const auto doc = QJsonDocument::fromJson(reply->readAll());
            if (!doc.isArray()) {
                qWarning() << "[TemplateManager] Invalid template index JSON received from:" << indexUrl;
                setPending(false);
                emit fetchFailed(tr("Invalid template list JSON."));
                return;
            }

            const QJsonArray repoList = doc.array();
            if (repoList.isEmpty())
            {
                setPending(false);
                return;
            }

            m_pendingRequests = repoList.size();
            for (const auto& value : repoList)
            {
                fetchIndividualTemplate(value.toString());
            }
        });
    }

    auto TemplateManager::fetchIndividualTemplate(const QString& repositoryUrl) -> void
    {
        const QUrl detailUrl(TemplateUrlResolver::templateJsonUrl(repositoryUrl));
        QNetworkRequest request(detailUrl);
        request.setRawHeader("User-Agent", "noi_engine_editor");
        QNetworkReply* reply = m_networkManager.get(request);

        connect(reply, &QNetworkReply::finished, this, [this, reply, repositoryUrl, detailUrl]() -> void {
            reply->deleteLater();

            if (reply->error() == QNetworkReply::NoError) {
                const auto doc = QJsonDocument::fromJson(reply->readAll());
                if (doc.isObject()) {
                    QVariantMap tMap = doc.object().toVariantMap();
                    tMap["repositoryUrl"] = repositoryUrl;
                    m_templates.append(tMap);
                } else {
                    qWarning() << "[TemplateManager] Invalid template metadata JSON from repository:" << repositoryUrl;
                }
            } else {
                qWarning() << "[TemplateManager] Failed to fetch template metadata from:" << detailUrl
                           << "(repository:" << repositoryUrl << ")"
                           << "| Error:" << reply->errorString();
            }

            m_pendingRequests--;
            checkCompletion();
        });
    }

    auto TemplateManager::checkCompletion() -> void
    {
        if (m_pendingRequests <= 0) {
            setPending(false);
            emit templatesChanged();
        }
    }
}