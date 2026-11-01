#pragma once

#include <QByteArray>
#include <QString>
#include <QNetworkAccessManager>
#include <functional>

namespace noi_engine_editor
{
    class TemplateInstaller
    {
    public:
        explicit TemplateInstaller(QNetworkAccessManager& networkManager);

        auto install(
            const QString& templateId,
            const QString& version,
            const QString& repositoryUrl,
            const std::function<void(bool success)>& onFinished
        ) -> void;

    private:
        static auto extractAndUnwrap(const QString& targetPath, const QByteArray& zipData) -> bool;

        QNetworkAccessManager& m_networkManager;
    };
}
