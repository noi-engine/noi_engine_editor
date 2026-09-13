#pragma once

#include <QQuickItem>
#include <QQuickFramebufferObject>
#include <QSet>
#include <QVariantList>
#include <QVector>

class QKeyEvent;

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

    // Same rationale as PendingPropertyEdit, but for a material resource rather than an
    // entity's component (no componentType - materials aren't ECS components).
    struct PendingMaterialPropertyEdit
    {
        quint32 materialId{};
        quint32 materialGeneration{};
        QString propertyName;
        QString propertyType;
        QVariant value;
    };

    // Same rationale as PendingPropertyEdit: queued until synchronize() applies it. keyCode
    // matches noi_engine::key_code's numeric layout (SDL_Scancode-compatible), translated
    // from Qt::Key in keyPressEvent/keyReleaseEvent.
    struct PendingKeyEvent
    {
        int keyCode{};
        bool pressed{};
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
        Q_PROPERTY(bool hasInspectedMaterial READ hasInspectedMaterial WRITE setHasInspectedMaterial
                       NOTIFY inspectedMaterialChanged)
        Q_PROPERTY(quint32 inspectedMaterialId READ inspectedMaterialId WRITE setInspectedMaterialId
                       NOTIFY inspectedMaterialChanged)
        Q_PROPERTY(quint32 inspectedMaterialGeneration READ inspectedMaterialGeneration
                       WRITE setInspectedMaterialGeneration NOTIFY inspectedMaterialChanged)
        Q_PROPERTY(QVariantList inspectedMaterialProperties READ inspectedMaterialProperties
                       NOTIFY inspectedMaterialPropertiesChanged)
        Q_PROPERTY(QString resourcesPath READ resourcesPath WRITE setResourcesPath NOTIFY resourcesPathChanged)
        Q_PROPERTY(QString scriptsLibraryPath READ scriptsLibraryPath WRITE setScriptsLibraryPath NOTIFY scriptsLibraryPathChanged)
        Q_PROPERTY(QString bridgeLibraryPath READ bridgeLibraryPath WRITE setBridgeLibraryPath NOTIFY bridgeLibraryPathChanged)
        Q_PROPERTY(int scriptsGeneration READ scriptsGeneration WRITE setScriptsGeneration NOTIFY scriptsGenerationChanged)
        Q_PROPERTY(QString engineVersion READ engineVersion WRITE setEngineVersion NOTIFY engineVersionChanged)
        Q_PROPERTY(int gameWidth READ gameWidth WRITE setGameWidth NOTIFY gameWidthChanged)
        Q_PROPERTY(int gameHeight READ gameHeight WRITE setGameHeight NOTIFY gameHeightChanged)
        // Read-only from QML on purpose: reflects the *confirmed* play state, only ever flipped
        // to false by confirmStopped() from the render thread (see OpenGLRenderer::synchronize()),
        // never synchronously from setPlaying(false) - see setPlaying() for why.
        Q_PROPERTY(bool playing READ isPlaying NOTIFY playingChanged)

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

        // Same primitives-only rationale as the inspectedEntity* properties above.
        bool hasInspectedMaterial() const;
        void setHasInspectedMaterial(bool hasMaterial);

        quint32 inspectedMaterialId() const;
        void setInspectedMaterialId(quint32 materialId);

        quint32 inspectedMaterialGeneration() const;
        void setInspectedMaterialGeneration(quint32 materialGeneration);

        QVariantList inspectedMaterialProperties() const;
        void setInspectedMaterialProperties(const QVariantList& properties); // renderer-only

        Q_INVOKABLE void setMaterialProperty(quint32 materialId, quint32 materialGeneration,
                                              const QString& propertyName, const QString& propertyType,
                                              const QVariant& value);
        QVector<PendingMaterialPropertyEdit> takePendingMaterialPropertyEdits();

        [[nodiscard]] bool isPlaying() const;

        // Called from QML's Play/Stop button.
        //
        // playing=true: takes effect immediately (no editing is currently locked yet, so there's
        // nothing that must finish first) - flips the property, grabs keyboard focus, nudges a
        // render.
        //
        // playing=false: does NOT flip the property synchronously. update() only *schedules* a
        // future frame, so unlocking the Inspector/Hierarchy right here could race ahead of the
        // final key-release/tick actually reaching the bridge. Instead this queues synthesized
        // release events for every currently-held key and sets stopRequested(); only
        // OpenGLRenderer::synchronize() calls confirmStopped(), and only after it has applied
        // those releases through the bridge. This guarantees "the system stops first".
        Q_INVOKABLE void setPlaying(bool playing);

        // Renderer-only: true from the Stop click until synchronize() has applied the final
        // key releases and called confirmStopped().
        [[nodiscard]] bool stopRequested() const;

        // Renderer-only: returns and clears all key events queued since the last call. Same
        // no-mutex rendezvous-point rule as takePendingPropertyEdits().
        QVector<PendingKeyEvent> takePendingKeyEvents();

        // Renderer-only: called from synchronize() once the final tick after a Stop request has
        // actually applied the queued key releases through the bridge. Flips playing to false and
        // emits playingChanged() - only from here, never from setPlaying(false) directly.
        void confirmStopped();

        [[nodiscard]] Renderer* createRenderer() const override;

    protected:
        void keyPressEvent(QKeyEvent* event) override;
        void keyReleaseEvent(QKeyEvent* event) override;

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
        void inspectedMaterialChanged();
        void inspectedMaterialPropertiesChanged();
        void playingChanged();

    private:
        void queueKeyEvent(int keyCode, bool pressed);

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
        bool m_hasInspectedMaterial = false;
        quint32 m_inspectedMaterialId = 0;
        quint32 m_inspectedMaterialGeneration = 0;
        QVariantList m_inspectedMaterialProperties;
        QVector<PendingMaterialPropertyEdit> m_pendingMaterialPropertyEdits;
        bool m_playing = false;
        bool m_stopRequested = false;
        QSet<int> m_pressedQtKeys;
        QVector<PendingKeyEvent> m_pendingKeyEvents;
    };
}
