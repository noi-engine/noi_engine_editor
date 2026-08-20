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
    public:
        explicit OpenGLView(QQuickItem *parent = nullptr);

        QString scenePath() const;
        void setScenePath(const QString& path);

        [[nodiscard]] Renderer *createRenderer() const override;

    signals:
        void scenePathChanged();

    private:
        QString m_scenePath;
    };
}