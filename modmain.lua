local Gibberish_EnemyFollowHealthBar = require "widgets.gibberish_enemyfollowhealthbar"

local always_shown = GetModConfigData("always_shown", true) == 2
local show_values = GetModConfigData("show_values", true) == 2

local function AddEnemyFollowHealthBar(inst, uicolor)
    -- (required) the color used for followhealthbar
    inst.uicolor = uicolor or GLOBAL.UICOLORS.OVERLAY_LIGHT
    inst.follow_health_bar = GLOBAL.TheDungeon.HUD:OverlayElement(Gibberish_EnemyFollowHealthBar(inst, always_shown, show_values))
end

AddPrefabPostInitAny(function(inst)
    if inst:HasTag("mob") and
    not (inst:HasTag("miniboss") or inst:HasTag("boss") or inst:HasTag("clone")) then
        if not GLOBAL.TheDungeon or not GLOBAL.TheDungeon.HUD then return end
        AddEnemyFollowHealthBar(inst)
    end
end)
