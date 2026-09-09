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

        Q_PROPERTY(QString path READ path NOTIFY projectChanged)
        Q_PROPERTY(bool isOpen READ isOpen NOTIFY projectChanged)

    public:
        explicit CurrentProjectManager(QObject* parent = nullptr);

        Q_INVOKABLE auto closeProject() -> void;
        Q_INVOKABLE [[nodiscard]] auto openProject(const QString& path) -> bool;
        Q_INVOKABLE [[nodiscard]] auto saveProject() const -> bool;
        Q_INVOKABLE [[nodiscard]] auto resourcesPath() const -> QString;
        Q_INVOKABLE [[nodiscard]] auto scriptsLibraryPath() const -> QString;
        Q_INVOKABLE [[nodiscard]] auto bridgeLibraryPath() const -> QString;

        [[nodiscard]] auto path() const -> QString;
        [[nodiscard]] auto isOpen() const -> bool;

        [[nodiscard]] auto name() const -> QString;
        [[nodiscard]] auto version() const -> QString;
        [[nodiscard]] auto category() const -> QString;
        [[nodiscard]] auto startScene() const -> QString;
        [[nodiscard]] auto engineVersion() const -> QString;
        [[nodiscard]] auto windowWidth() const -> int;
        [[nodiscard]] auto windowHeight() const -> int;

        auto setWindowWidth(int width) -> void;
        auto setWindowHeight(int height) -> void;
        auto setName(const QString& name) -> void;
        auto setVersion(const QString& version) -> void;
        auto setCategory(const QString& category) -> void;
        auto setStartScene(const QString& startScene) -> void;

    signals:
        void projectChanged();
        void projectOpenFailed(const QString& reason);

        void nameChanged();
        void versionChanged();
        void categoryChanged();
        void startSceneChanged();
        void engineVersionChanged();
        void windowWidthChanged();
        void windowHeightChanged();

    private:
        QString m_path;
        ProjectInfo m_project{};
        bool m_isOpen{false};
    };
}
