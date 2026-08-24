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
        Q_PROPERTY(int gameWidth READ gameWidth WRITE setGameWidth NOTIFY gameWidthChanged)
        Q_PROPERTY(int gameHeight READ gameHeight WRITE setGameHeight NOTIFY gameHeightChanged)

    public:
        explicit OpenGLView(QQuickItem* parent = nullptr);

        QString scenePath() const;
        void setScenePath(const QString& path);

        QString resourcesPath() const;
        void setResourcesPath(const QString& path);

        int gameWidth() const;
        void setGameWidth(int width);

        int gameHeight() const;
        void setGameHeight(int height);

        [[nodiscard]] Renderer* createRenderer() const override;

    signals:
        void scenePathChanged();
        void cameraZoomChanged();
        void resourcesPathChanged();
        void gameWidthChanged();
        void gameHeightChanged();

    private:
        QString m_scenePath;
        QString m_resourcesPath;
        int m_gameWidth = 0;
        int m_gameHeight = 0;
    };
}
