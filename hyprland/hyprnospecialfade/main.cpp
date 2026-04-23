#define WLR_USE_UNSTABLE

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/config/ConfigManager.hpp>
#include <hyprland/src/desktop/Workspace.hpp>
#include <hyprland/src/managers/animation/DesktopAnimationManager.hpp>
#include <hyprland/src/plugins/PluginAPI.hpp>

inline HANDLE PHANDLE = nullptr;

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

static CFunctionHook* g_pHook = nullptr;

using startAnimation_t = void (*)(CDesktopAnimationManager*, PHLWORKSPACE, CDesktopAnimationManager::eAnimationType, bool, bool);

void hkStartAnimation(CDesktopAnimationManager* self, PHLWORKSPACE ws, CDesktopAnimationManager::eAnimationType type, bool left, bool instant) {
    (*(startAnimation_t)g_pHook->m_original)(self, ws, type, left, instant);

    if (!ws || !ws->m_isSpecialWorkspace)
        return;

    auto animName = (type == CDesktopAnimationManager::ANIMATION_TYPE_IN) ? "specialWorkspace" : "specialWorkspaceOut";
    auto pConfig  = g_pConfigManager->getAnimationPropertyConfig(animName);
    if (pConfig && pConfig->internalStyle == "fade")
        return;

    (*ws->m_alpha) = 1.0f;
    ws->m_alpha->warp(false, true);
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    PHANDLE = handle;

    const std::string HASH        = __hyprland_api_get_hash();
    const std::string CLIENT_HASH = __hyprland_api_get_client_hash();

    if (HASH != CLIENT_HASH) {
        HyprlandAPI::addNotification(PHANDLE, "[hyprnospecialfade] Version mismatch — rebuild required", CHyprColor{1.0, 0.2, 0.2, 1.0}, 5000);
        throw std::runtime_error("[hyprnospecialfade] Version mismatch");
    }

    auto functions = HyprlandAPI::findFunctionsByName(PHANDLE, "startAnimation");
    void* target   = nullptr;
    for (auto& f : functions) {
        if (f.demangled.find("CDesktopAnimationManager::startAnimation") != std::string::npos &&
            f.demangled.find("CWorkspace") != std::string::npos) {
            target = f.address;
            break;
        }
    }

    if (!target) {
        HyprlandAPI::addNotification(PHANDLE, "[hyprnospecialfade] Could not find startAnimation hook target", CHyprColor{1.0, 0.2, 0.2, 1.0}, 5000);
        throw std::runtime_error("[hyprnospecialfade] Hook target not found");
    }

    g_pHook = HyprlandAPI::createFunctionHook(PHANDLE, target, (void*)&hkStartAnimation);
    if (!g_pHook || !g_pHook->hook()) {
        HyprlandAPI::addNotification(PHANDLE, "[hyprnospecialfade] Failed to hook startAnimation", CHyprColor{1.0, 0.2, 0.2, 1.0}, 5000);
        throw std::runtime_error("[hyprnospecialfade] Hook failed");
    }

    HyprlandAPI::addNotification(PHANDLE, "[hyprnospecialfade] Loaded — special workspace fade disabled", CHyprColor{0.2, 1.0, 0.2, 1.0}, 3000);
    return {"hyprnospecialfade", "Disables hardcoded fade on special workspace animations", "Trev", "1.0"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    if (g_pHook)
        g_pHook->unhook();
}
