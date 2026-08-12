#include "TemplateManager.hpp"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QDebug>
#include <QtGui/private/qzipreader_p.h>

namespace noi_engine_editor
{
    TemplateManager::TemplateManager(QObject* parent) : QObject(parent) {}

    QString TemplateManager::templatesStoragePath() const
    {
        QString path = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/Templates";
        QDir().mkpath(path);
        return path;
    }

    bool TemplateManager::isTemplateDownloaded(const QString& templateId) const
    {
        if (templateId.isEmpty()) return false;
        QString folder = templatesStoragePath() + "/" + templateId;
        return QDir(folder).exists() && QFile::exists(folder + "/noi-engine.template.json");
    }

    QString TemplateManager::convertToRawJsonUrl(const QString& repoUrl) const
    {
        QString url = repoUrl;
        if (url.endsWith("/")) url.chop(1);
        url.replace("https://github.com/", "https://raw.githubusercontent.com/");
        return url + "/main/noi-engine.template.json";
    }

    QString TemplateManager::convertToZipUrl(const QString& repoUrl) const
    {
        QString url = repoUrl;
        if (url.endsWith("/")) url.chop(1);
        return url + "/archive/refs/heads/main.zip";
    }

    void TemplateManager::fetchCatalog(const QString& indexUrl)
    {
        m_isLoading = true;
        emit isLoadingChanged();
        m_templates.clear();

        QNetworkRequest request{QUrl(indexUrl)};
        QNetworkReply* reply = m_networkManager.get(request);

        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
                if (doc.isArray()) {
                    QJsonArray repoList = doc.array();
                    m_pendingRequests = repoList.size();

                    if (m_pendingRequests == 0) {
                        m_isLoading = false;
                        emit isLoadingChanged();
                        emit templatesChanged();
                    }

                    for (const auto& val : repoList) {
                        fetchMetadataFromRepoUrl(val.toString(), repoList.size());
                    }
                }
            } else {
                m_isLoading = false;
                emit isLoadingChanged();
            }
            reply->deleteLater();
        });
    }

    void TemplateManager::fetchMetadataFromRepoUrl(const QString& repoUrl, int totalRepos)
    {
        QString rawUrl = convertToRawJsonUrl(repoUrl);
        QNetworkRequest request{QUrl(rawUrl)};
        QNetworkReply* reply = m_networkManager.get(request);

        connect(reply, &QNetworkReply::finished, this, [this, reply, repoUrl]() {
            m_pendingRequests--;

            if (reply->error() == QNetworkReply::NoError) {
                QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
                if (doc.isObject()) {
                    QJsonObject obj = doc.object();
                    QVariantMap map;

                    QString id = obj["id"].toString();
                    map["id"] = id;
                    map["name"] = obj["name"].toString();
                    map["version"] = obj["version"].toString();
                    map["description"] = obj["description"].toString();
                    map["author"] = obj["author"].toString();
                    map["repoUrl"] = repoUrl;
                    map["isDownloaded"] = isTemplateDownloaded(id);

                    m_templates.append(map);
                }
            }

            if (m_pendingRequests <= 0) {
                m_isLoading = false;
                emit isLoadingChanged();
                emit templatesChanged();
            }

            reply->deleteLater();
        });
    }

    void TemplateManager::downloadTemplate(const QString& templateId)
    {
        QString repoUrl;
        for (const auto& item : m_templates) {
            QVariantMap map = item.toMap();
            if (map["id"].toString() == templateId) {
                repoUrl = map["repoUrl"].toString();
                break;
            }
        }

        if (repoUrl.isEmpty()) {
            emit downloadFinished(templateId, false, "Repository URL dynamic resolve failed.");
            return;
        }

        QString zipUrl = convertToZipUrl(repoUrl);
        QNetworkRequest request{QUrl(zipUrl)};
        request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

        QNetworkReply* reply = m_networkManager.get(request);

        connect(reply, &QNetworkReply::downloadProgress, this, [this, templateId](qint64 bytesReceived, qint64 bytesTotal) {
            emit downloadProgress(templateId, bytesReceived, bytesTotal);
        });

        connect(reply, &QNetworkReply::finished, this, [this, reply, templateId]() {
            if (reply->error() == QNetworkReply::NoError) {
                QByteArray zipData = reply->readAll();

                // Enregistrer temporairement l'archive ZIP
                QString tempZipPath = templatesStoragePath() + "/" + templateId + ".zip";
                QFile tempFile(tempZipPath);
                if (tempFile.open(QIODevice::WriteOnly)) {
                    tempFile.write(zipData);
                    tempFile.close();

                    // Extraction du ZIP
                    QString targetFolder = templatesStoragePath() + "/" + templateId;
                    QDir().mkpath(targetFolder);

                    QZipReader reader(tempZipPath);
                    if (reader.status() == QZipReader::NoError) {
                        reader.extractAll(targetFolder);
                        reader.close();
                        QFile::remove(tempZipPath); // Suppression du fichier ZIP temporaire

                        for (int i = 0; i < m_templates.size(); ++i) {
                            QVariantMap map = m_templates[i].toMap();
                            if (map["id"].toString() == templateId) {
                                map["isDownloaded"] = true;
                                m_templates[i] = map;
                            }
                        }
                        emit templatesChanged();
                        emit downloadFinished(templateId, true, "Downloaded and extracted successfully.");
                    } else {
                        emit downloadFinished(templateId, false, "Failed to extract ZIP archive.");
                    }
                }
            } else {
                emit downloadFinished(templateId, false, reply->errorString());
            }
            reply->deleteLater();
        });
    }
}