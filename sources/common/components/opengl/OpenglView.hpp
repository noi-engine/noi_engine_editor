#pragma once

#include <QQuickItem>
#include <QQuickFramebufferObject>
#include <QVariantList>
#include <QVector>

namespace noi_engine_editor
{
    // A single GUI-thread-initiated edit, queued until the next OpenGLRenderer::synchronize()
    // (the safe rendezvous point) applies it to the live engine and re-reads authoritative values.
    struct PendingPropertyEdit
    {
        quint32 entityId{};
        quint32 entityGeneration{};
        QString componentType;
        QString propertyName;
        QString propertyType;
        QVariant value;
    };

    // Same rationale as PendingPropertyEdit: queued until synchronize() applies it.
    struct PendingComponentAdd
    {
        quint32 entityId{};
        quint32 entityGeneration{};
        QString componentType;
    };

    class OpenGLView : public QQuickFramebufferObject
    {
        Q_OBJECT
        QML_ELEMENT
        Q_PROPERTY(QString scenePath READ scenePath WRITE setScenePath NOTIFY scenePathChanged)
        Q_PROPERTY(QVariantList loadedResources READ loadedResources NOTIFY loadedResourcesChanged)
        Q_PROPERTY(QVariantList loadedEntities READ loadedEntities NOTIFY loadedEntitiesChanged)
        Q_PROPERTY(bool hasInspectedEntity READ hasInspectedEntity WRITE setHasInspectedEntity NOTIFY inspectedEntityChanged)
        Q_PROPERTY(quint32 inspectedEntityId READ inspectedEntityId WRITE setInspectedEntityId NOTIFY inspectedEntityChanged)
        Q_PROPERTY(quint32 inspectedEntityGeneration READ inspectedEntityGeneration WRITE setInspectedEntityGeneration
                       NOTIFY inspectedEntityChanged)
        Q_PROPERTY(QVariantList inspectedComponents READ inspectedComponents NOTIFY inspectedComponentsChanged)
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

        QVariantList loadedResources() const;
        // Called only by OpenGLRenderer::synchronize(), the one safe rendezvous point
        // between the render thread (which owns the game handle) and this GUI-thread item.
        void setLoadedResources(const QVariantList& resources);

        QVariantList loadedEntities() const;
        void setLoadedEntities(const QVariantList& entities); // same rendezvous-point rule as setLoadedResources

        // These 3 are plain primitives on purpose - passing the selection as a single JS
        // object across the QML/C++ boundary risks silently landing as an unconvertible
        // QVariant (e.g. wrapped QJSValue) instead of a QVariantMap; primitives always
        // cross unambiguously.
        bool hasInspectedEntity() const;
        void setHasInspectedEntity(bool hasEntity);

        quint32 inspectedEntityId() const;
        void setInspectedEntityId(quint32 entityId);

        quint32 inspectedEntityGeneration() const;
        void setInspectedEntityGeneration(quint32 entityGeneration);

        QVariantList inspectedComponents() const;
        void setInspectedComponents(const QVariantList& components); // renderer-only, same rendezvous-point rule

        // Called from QML when the user edits a property field. Queued rather than applied
        // immediately: only the render thread (inside synchronize()) may touch the game handle.
        Q_INVOKABLE void setComponentProperty(quint32 entityId, quint32 entityGeneration,
                                               const QString& componentType, const QString& propertyName,
                                               const QString& propertyType, const QVariant& value);

        // Renderer-only: returns and clears all edits queued since the last call. Safe without
        // a mutex because it is only ever called from inside synchronize(), which Qt guarantees
        // runs with the GUI thread blocked - the same contract setLoadedResources() relies on.
        QVector<PendingPropertyEdit> takePendingPropertyEdits();

        // Called from QML to add a default-constructed component to an entity. Queued and
        // drained the same way as setComponentProperty.
        Q_INVOKABLE void addComponent(quint32 entityId, quint32 entityGeneration, const QString& componentType);
        QVector<PendingComponentAdd> takePendingComponentAdds();

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
        void loadedResourcesChanged();
        void loadedEntitiesChanged();
        void inspectedEntityChanged();
        void inspectedComponentsChanged();

    private:
        QString m_scenePath;
        QString m_resourcesPath;
        QString m_scriptsLibraryPath;
        QString m_bridgeLibraryPath;
        QString m_engineVersion;
        int m_scriptsGeneration = 0;
        int m_gameWidth = 0;
        int m_gameHeight = 0;
        QVariantList m_loadedResources;
        QVariantList m_loadedEntities;
        bool m_hasInspectedEntity = false;
        quint32 m_inspectedEntityId = 0;
        quint32 m_inspectedEntityGeneration = 0;
        QVariantList m_inspectedComponents;
        QVector<PendingPropertyEdit> m_pendingPropertyEdits;
        QVector<PendingComponentAdd> m_pendingComponentAdds;
    };
}
