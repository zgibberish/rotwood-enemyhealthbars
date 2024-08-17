local Widget = require "widgets.widget"
local Gibberish_EnemyFollowHealthBar = require "widgets.gibberish_enemyfollowhealthbar"

local always_shown = GetModConfigData("always_shown", true) == 2
local show_values = GetModConfigData("show_values", true) == 2

local function AddEnemyFollowHealthBar(inst, uicolor)
    -- (required) the color used for followhealthbar
    inst.uicolor = uicolor or GLOBAL.UICOLORS.OVERLAY_LIGHT
    inst.follow_health_bar = GLOBAL.TheDungeon.HUD:OverlayElement(Gibberish_EnemyFollowHealthBar(inst, always_shown, show_values))
end

GLOBAL.TheGlobalInstance:ListenForEvent("room_created", function(inst)
    -- post init event of monsters
    GLOBAL.TheWorld:ListenForEvent("spawnenemy", function(source, ent)
        if ent:HasTag("mob") and not (ent:HasTag("miniboss") or ent:HasTag("boss") or ent:HasTag("clone")) then
            ent:DoTaskInTicks(1, function()
                if GLOBAL.TheDungeon and GLOBAL.TheDungeon.HUD then
                    -- i think this doesnt work for normal rots when they spawn
                    -- in during cutscenes? (e.g: the start of bossfights) since
                    -- or at least last time i checked (need to work more on that)
                    AddEnemyFollowHealthBar(ent)
                end
            end)
        end
    end)
end)