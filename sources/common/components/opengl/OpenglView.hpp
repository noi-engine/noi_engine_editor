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
    public:
        explicit OpenGLView(QQuickItem *parent = nullptr);

        QString scenePath() const;
        void setScenePath(const QString& path);

        QString resourcesPath() const;
        void setResourcesPath(const QString& path);

        [[nodiscard]] Renderer *createRenderer() const override;

    signals:
        void scenePathChanged();
        void resourcesPathChanged();

    private:
        QString m_scenePath;
        QString m_resourcesPath;
    };
}