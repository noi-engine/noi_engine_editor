#pragma once

#include <QQmlEngine>
#include <QString>
#include <QVariantList>
#include <QNetworkAccessManager>

namespace noi_engine_editor
{
    class ToolsManager : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

        Q_PROPERTY(bool isInstallingNoiEngine READ isInstallingNoiEngine NOTIFY isInstallingNoiEngineChanged)
        Q_PROPERTY(bool isInstallingResourceCompiler READ isInstallingResourceCompiler NOTIFY isInstallingResourceCompilerChanged)
        Q_PROPERTY(bool isInstallingEditorBridge READ isInstallingEditorBridge NOTIFY isInstallingEditorBridgeChanged)
    public:
        explicit ToolsManager(QObject* parent = nullptr);

        [[nodiscard]] auto isInstallingNoiEngine() const -> bool;
        [[nodiscard]] auto isInstallingResourceCompiler() const -> bool;
        [[nodiscard]] auto isInstallingEditorBridge() const -> bool;

        Q_INVOKABLE [[nodiscard]] auto isNoiEngineInstalled(const QString& version) const -> bool;
        Q_INVOKABLE [[nodiscard]] auto isResourceCompilerInstalled(const QString& version) const -> bool;
        Q_INVOKABLE [[nodiscard]] auto isEditorBridgeInstalled(const QString& version) const -> bool;

        Q_INVOKABLE [[nodiscard]] auto installedNoiEngineVersions() const -> QVariantList;
        Q_INVOKABLE [[nodiscard]] auto installedResourceCompilerVersions() const -> QVariantList;
        Q_INVOKABLE [[nodiscard]] auto installedEditorBridgeVersions() const -> QVariantList;

        Q_INVOKABLE auto installNoiEngine(const QString& version) -> void;
        Q_INVOKABLE auto installResourceCompiler(const QString& version) -> void;
        Q_INVOKABLE auto installEditorBridge(const QString& version) -> void;
        Q_INVOKABLE auto removeNoiEngineVersion(const QString& version) -> void;
        Q_INVOKABLE auto removeResourceCompilerVersion(const QString& version) -> void;
        Q_INVOKABLE auto removeEditorBridgeVersion(const QString& version) -> void;

    signals:
        auto isInstallingNoiEngineChanged() -> void;
        auto isInstallingResourceCompilerChanged() -> void;
        auto isInstallingEditorBridgeChanged() -> void;
        auto installFinished(const QString& tool, const QString& version, bool success) -> void;

    private:
        auto setInstallingNoiEngine(bool installing) -> void;
        auto setInstallingResourceCompiler(bool installing) -> void;
        auto setInstallingEditorBridge(bool installing) -> void;

        QNetworkAccessManager m_networkManager;

        bool m_isInstallingNoiEngine = false;
        bool m_isInstallingResourceCompiler = false;
        bool m_isInstallingEditorBridge = false;
    };
}
