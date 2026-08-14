#include "LocalTemplateManager.hpp"
#include <QJsonObject>
#include <QVariantMap>

namespace noi_engine_editor
{
    LocalTemplateManager::LocalTemplateManager(QObject* parent)
        : QObject(parent)
    {
        loadLocalTemplates();
    }

    auto LocalTemplateManager::templates() const -> QVariantList
    {
        return m_templates;
    }

    auto LocalTemplateManager::loadLocalTemplates() -> void
    {
        m_templates.clear();

        // TODO: Implémenter le scan réel d'un dossier (ex: ~/.noi_engine/templates/)
        // Pour l'instant, liste statique simulant des templates téléchargés :
        QVariantMap basic2d;
        basic2d["id"] = "noi-2d-basic";
        basic2d["name"] = "2D Basic Template";
        basic2d["version"] = "1.0.0";
        basic2d["description"] = "A simple 2D scene starter with a camera and player node.";
        basic2d["author"] = "NoiEngine Team";

        QVariantMap emptyProj;
        emptyProj["id"] = "noi-empty";
        emptyProj["name"] = "Empty Project";
        emptyProj["version"] = "1.0.0";
        emptyProj["description"] = "A blank project with minimal configuration.";
        emptyProj["author"] = "NoiEngine Team";

        m_templates.append(basic2d);
        m_templates.append(emptyProj);

        emit templatesChanged();
    }
}