#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QVariantList>

namespace noi_engine_editor
{
    // What the machine needs to build and ship a game: cmake, a build tool, a C++ compiler,
    // python and flatc. Looked up in the PATH; the editor shows what's missing and how to
    // install it instead of letting a build fail with a cryptic message.
    class PrerequisitesManager : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

        // [{id, label, purpose, found, path, required ("build" or "release"), hint}]
        Q_PROPERTY(QVariantList items READ items NOTIFY itemsChanged)
        // cmake + ninja + a C++ compiler: enough to Compile and Play.
        Q_PROPERTY(bool canBuild READ canBuild NOTIFY itemsChanged)
        // + python3 + flatc: enough to Build Release.
        Q_PROPERTY(bool canRelease READ canRelease NOTIFY itemsChanged)
        Q_PROPERTY(QString missingSummary READ missingSummary NOTIFY itemsChanged)

    public:
        explicit PrerequisitesManager(QObject* parent = nullptr);

        Q_INVOKABLE auto refresh() -> void;

        [[nodiscard]] auto items() const -> QVariantList;
        [[nodiscard]] auto canBuild() const -> bool;
        [[nodiscard]] auto canRelease() const -> bool;
        [[nodiscard]] auto missingSummary() const -> QString;

    signals:
        void itemsChanged();

    private:
        QVariantList m_items;
        bool m_canBuild{false};
        bool m_canRelease{false};
        QString m_missingSummary;
    };
}
