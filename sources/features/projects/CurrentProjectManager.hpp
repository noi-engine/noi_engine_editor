#pragma once

#include <QQmlEngine>
#include <QString>
#include "ProjectInfo.hpp"

namespace noi_engine_editor
{
    class CurrentProjectManager : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

        Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
        Q_PROPERTY(QString version READ version WRITE setVersion NOTIFY versionChanged)
        Q_PROPERTY(QString category READ category WRITE setCategory NOTIFY categoryChanged)
        Q_PROPERTY(QString startScene READ startScene WRITE setStartScene NOTIFY startSceneChanged)
        Q_PROPERTY(QString engineVersion READ engineVersion NOTIFY engineVersionChanged)
        Q_PROPERTY(int windowWidth READ windowWidth WRITE setWindowWidth NOTIFY windowWidthChanged)
        Q_PROPERTY(int windowHeight READ windowHeight WRITE setWindowHeight NOTIFY windowHeightChanged)
        // Editor viewport state saved with the project: {zoom, world_width, world_height, scroll_x, scroll_y}.
        Q_PROPERTY(QVariantMap editorView READ editorView WRITE setEditorView NOTIFY editorViewChanged)

        Q_PROPERTY(QString path READ path NOTIFY projectChanged)
        Q_PROPERTY(bool isOpen READ isOpen NOTIFY projectChanged)

        // Why the last openProject() failed, and the editor bridge version to download when
        // that's the only thing missing (empty otherwise).
        Q_PROPERTY(QString lastOpenError READ lastOpenError NOTIFY lastOpenErrorChanged)
        Q_PROPERTY(QString missingEditorBridgeVersion READ missingEditorBridgeVersion NOTIFY lastOpenErrorChanged)

    public:
        explicit CurrentProjectManager(QObject* parent = nullptr);

        Q_INVOKABLE auto closeProject() -> void;
        // Refuses (with lastOpenError set) projects this editor can't run: invalid project file,
        // no editor_bridge_version, or a bridge that is missing or doesn't support the engine.
        Q_INVOKABLE [[nodiscard]] auto openProject(const QString& path) -> bool;
        Q_INVOKABLE [[nodiscard]] static bool isProjectFolder(const QString& path);
        Q_INVOKABLE [[nodiscard]] auto saveProject() const -> bool;
        Q_INVOKABLE [[nodiscard]] auto resourcesPath() const -> QString;
        Q_INVOKABLE [[nodiscard]] auto scriptsLibraryPath() const -> QString;
        // Editor bridge from the editor's tools folder, or empty (with a warning) if it isn't
        // installed or can't run this project's engine version.
        Q_INVOKABLE [[nodiscard]] auto bridgeLibraryPath() const -> QString;
        // The project's own noi_engine library, loaded before the bridge so the bridge and the
        // game's scripts share it.
        Q_INVOKABLE [[nodiscard]] auto engineLibraryPath() const -> QString;

        [[nodiscard]] auto path() const -> QString;
        [[nodiscard]] auto isOpen() const -> bool;
        [[nodiscard]] auto lastOpenError() const -> QString;
        [[nodiscard]] auto missingEditorBridgeVersion() const -> QString;

        [[nodiscard]] auto name() const -> QString;
        [[nodiscard]] auto version() const -> QString;
        [[nodiscard]] auto category() const -> QString;
        [[nodiscard]] auto startScene() const -> QString;
        [[nodiscard]] auto engineVersion() const -> QString;
        [[nodiscard]] auto windowWidth() const -> int;
        [[nodiscard]] auto windowHeight() const -> int;
        [[nodiscard]] auto editorView() const -> QVariantMap;
        auto setEditorView(const QVariantMap& view) -> void;

        auto setWindowWidth(int width) -> void;
        auto setWindowHeight(int height) -> void;
        auto setName(const QString& name) -> void;
        auto setVersion(const QString& version) -> void;
        auto setCategory(const QString& category) -> void;
        auto setStartScene(const QString& startScene) -> void;

    signals:
        void projectChanged();
        void projectOpenFailed(const QString& reason);
        void lastOpenErrorChanged();

        void nameChanged();
        void versionChanged();
        void categoryChanged();
        void startSceneChanged();
        void engineVersionChanged();
        void windowWidthChanged();
        void windowHeightChanged();
        void editorViewChanged();

    private:
        QString m_path;
        ProjectInfo m_project{};
        bool m_isOpen{false};
        QString m_lastOpenError;
        QString m_missingEditorBridgeVersion;

        auto failOpen(const QString& reason, const QString& missingEditorBridgeVersion = {}) -> bool;
    };
}
