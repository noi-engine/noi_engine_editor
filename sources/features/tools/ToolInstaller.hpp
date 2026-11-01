#pragma once

#include <QNetworkAccessManager>
#include <functional>

namespace noi_engine_editor
{
    class ToolInstaller
    {
    public:
        explicit ToolInstaller(QNetworkAccessManager& networkManager);

        auto install(const QString& downloadUrl, const QString& targetPath, const std::function<void(bool success)>& onFinished) -> void;

    private:
        QNetworkAccessManager& m_networkManager;
    };
}
