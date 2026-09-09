#pragma once

#include <QQuickItem>
#include <QQuickFramebufferObject>

namespace noi_engine_editor
{
    class OpenGLView : public QQuickFramebufferObject
    {
        Q_OBJECT
        QML_ELEMENT
        Q_PROPERTY(QString scenePath READ scenePath WRITE setScenePath NOTIFY scenePathChanged)
        Q_PROPERTY(QString resourcesPath READ resourcesPath WRITE setResourcesPath NOTIFY resourcesPathChanged)
        Q_PROPERTY(QString scriptsLibraryPath READ scriptsLibraryPath WRITE setScriptsLibraryPath NOTIFY scriptsLibraryPathChanged)
        Q_PROPERTY(QString bridgeLibraryPath READ bridgeLibraryPath WRITE setBridgeLibraryPath NOTIFY bridgeLibraryPathChanged)
        Q_PROPERTY(int scriptsGeneration READ scriptsGeneration WRITE setScriptsGeneration NOTIFY scriptsGenerationChanged)
        Q_PROPERTY(QString engineVersion READ engineVersion WRITE setEngineVersion NOTIFY engineVersionChanged)
        Q_PROPERTY(int gameWidth READ gameWidth WRITE setGameWidth NOTIFY gameWidthChanged)
        Q_PROPERTY(int gameHeight READ gameHeight WRITE setGameHeight NOTIFY gameHeightChanged)

    public:
        explicit OpenGLView(QQuickItem* parent = nullptr);

        QString scenePath() const;
        void setScenePath(const QString& path);

        QString resourcesPath() const;
        void setResourcesPath(const QString& path);

        QString scriptsLibraryPath() const;
        void setScriptsLibraryPath(const QString& path);

        QString bridgeLibraryPath() const;
        void setBridgeLibraryPath(const QString& path);

        int scriptsGeneration() const;
        void setScriptsGeneration(int generation);

        QString engineVersion() const;
        void setEngineVersion(const QString& version);

        int gameWidth() const;
        void setGameWidth(int width);

        int gameHeight() const;
        void setGameHeight(int height);

        [[nodiscard]] Renderer* createRenderer() const override;

    signals:
        void scenePathChanged();
        void cameraZoomChanged();
        void resourcesPathChanged();
        void scriptsLibraryPathChanged();
        void bridgeLibraryPathChanged();
        void scriptsGenerationChanged();
        void engineVersionChanged();
        void gameWidthChanged();
        void gameHeightChanged();

    private:
        QString m_scenePath;
        QString m_resourcesPath;
        QString m_scriptsLibraryPath;
        QString m_bridgeLibraryPath;
        QString m_engineVersion;
        int m_scriptsGeneration = 0;
        int m_gameWidth = 0;
        int m_gameHeight = 0;
    };
}
