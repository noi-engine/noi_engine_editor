#include "PrerequisitesManager.hpp"

#include <QStandardPaths>
#include <QStringList>
#include <QVariantMap>

namespace
{
    struct Tool
    {
        QString id;
        QString label;
        QString purpose;
        QStringList executables; // the first one found counts
        QString required;        // "build": Compile / Play, "release": Build Release only
        QString hint;
    };

    auto installCommand(const QString& linux, const QString& mac, const QString& windows) -> QString
    {
#if defined(Q_OS_MACOS)
        Q_UNUSED(linux) Q_UNUSED(windows)
        return mac;
#elif defined(Q_OS_WIN)
        Q_UNUSED(linux) Q_UNUSED(mac)
        return windows;
#else
        Q_UNUSED(mac) Q_UNUSED(windows)
        return linux;
#endif
    }

    auto tools() -> QList<Tool>
    {
        return {
            {"cmake", "CMake", QObject::tr("Configures your game's build"), {"cmake"}, "build",
             installCommand("sudo apt install cmake   (or: sudo pacman -S cmake)", "brew install cmake",
                            "winget install Kitware.CMake")},
            {"ninja", "Ninja", QObject::tr("Builds your game quickly"), {"ninja", "ninja-build"}, "build",
             installCommand("sudo apt install ninja-build   (or: sudo pacman -S ninja)", "brew install ninja",
                            "winget install Ninja-build.Ninja")},
            {"compiler", "C++ compiler (clang++)", QObject::tr("Compiles your scripts"), {"clang++", "g++", "c++"}, "build",
             installCommand("sudo apt install clang   (or: sudo pacman -S clang)", "xcode-select --install",
                            "winget install LLVM.LLVM")},
            {"python", "Python 3", QObject::tr("Runs the resources compiler (release builds)"), {"python3", "python"}, "release",
             installCommand("sudo apt install python3 python3-venv   (or: sudo pacman -S python)", "brew install python",
                            "winget install Python.Python.3.12")},
            {"flatc", "flatc (FlatBuffers)", QObject::tr("Packs scenes for release builds"), {"flatc"}, "release",
             installCommand("sudo apt install flatbuffers-compiler   (or: sudo pacman -S flatbuffers)", "brew install flatbuffers",
                            "vcpkg install flatbuffers")},
        };
    }
}

namespace noi_engine_editor
{
    PrerequisitesManager::PrerequisitesManager(QObject* parent) : QObject(parent)
    {
        refresh();
    }

    auto PrerequisitesManager::refresh() -> void
    {
        QVariantList items;
        bool canBuild = true;
        bool canRelease = true;
        QStringList missing;

        for (const auto& tool : tools())
        {
            QString path;
            for (const auto& executable : tool.executables)
            {
                path = QStandardPaths::findExecutable(executable);
                if (!path.isEmpty())
                {
                    break;
                }
            }

            const auto found = !path.isEmpty();
            if (!found)
            {
                missing.append(tool.label);
                canRelease = false;
                if (tool.required == QStringLiteral("build"))
                {
                    canBuild = false;
                }
            }

            QVariantMap item;
            item["id"] = tool.id;
            item["label"] = tool.label;
            item["purpose"] = tool.purpose;
            item["found"] = found;
            item["path"] = path;
            item["required"] = tool.required;
            item["hint"] = tool.hint;
            items.append(item);
        }

        m_items = items;
        m_canBuild = canBuild;
        m_canRelease = canRelease;
        m_missingSummary = missing.join(QStringLiteral(", "));
        emit itemsChanged();
    }

    auto PrerequisitesManager::items() const -> QVariantList { return m_items; }
    auto PrerequisitesManager::canBuild() const -> bool { return m_canBuild; }
    auto PrerequisitesManager::canRelease() const -> bool { return m_canRelease; }
    auto PrerequisitesManager::missingSummary() const -> QString { return m_missingSummary; }
}
