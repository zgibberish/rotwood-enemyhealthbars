local Image = require "widgets.image"
local Power = require "defs.powers"
local ShieldPips = require("widgets/shieldpips")
local Widget = require("widgets/widget")
local easing = require "util.easing"
local SegmentedHealthBar = require("widgets/ftf/segmentedhealthbar")

local Y_OFFSET = -42
local SCALE = 0.35 * HACK_FOR_4K -- same as player follow health bar

local Gibberish_EnemyFollowHealthBar =  Class(Widget, function(self, owner, always_shown, show_values)
	Widget._ctor(self, "Gibberish_EnemyFollowHealthBar")

	self.always_shown = always_shown or false
	self.show_values = show_values or false

	self:SetScaleMode(SCALEMODE_PROPORTIONAL)

	-- Widgets container
	self.container = self:AddChild(Widget())
	self.container:AlphaTo(0, 0, easing.outQuad)

	self.shield_pips = self.container:AddChild(ShieldPips(owner))
		:SetScale(1, 1)

	self.hp_bar = self.container:AddChild( SegmentedHealthBar(owner) )
		:SetHealthBounds(150, 1000, 1500)
		:SetScale(SCALE, SCALE)
		:SendToBack()
		:LayoutBounds("center", "below", self.shield_pips)

	self.hp_bar.text:SetFontSize(64)
	self.hp_bar.outline:SetFontSize(64)
	local og_UpdateText = self.hp_bar.UpdateText
	self.hp_bar.UpdateText = function()
		og_UpdateText(self.hp_bar)
		self.hp_bar.text_root:LayoutBounds("center", "above", self.bg)
			:Offset(0, 12 * HACK_FOR_4K)
	end
	self.hp_bar.UpdateText()
	
	if self.show_values then
		self.hp_bar.text_root:Show()
	else
		self.hp_bar.text_root:Hide()
	end

	self.hp_bar:SetOnSizeChangeFn(function()
		self.hp_bar:LayoutBounds("center", "below", self.shield_pips)
		self:UpdateShieldBGSize()
	end)

	self.shield_hp_border = self.container:AddChild(Image("images/ui_ftf_ingame/ui_shield_hp_border.tex"))
		:SetScale(SCALE, 0.3)
		:AlphaTo(0, 0, easing.outExpo)
		:SendToBack()

	self:UpdateShieldBGSize()

	self.fade_out_time = 0.25
	self.time_visible = 2.0 -- how long the bar is visible after showing damage
	self.time_visible_shield = 3.0 -- how long the bar is visible after showing damage when you have a shield power

	self._ondeath = function() self:Remove() end
	self._onremovetarget = function() self:SetOwner(nil) end
	self._onmaxhealthchanged = function (target, data) self:Reveal() end
	self._onhealthchanged = function(target, data) if data and not data.silent and data.old ~= data.new then self:Reveal() end end
	self._onupdate_power = function(source, data) self:OnUpdatePower(data) end
	self._onupdate_ui_color = function(source, rgb) self:_RefreshColor() end
	self._onadd_power = function(source, data) self:OnAddPower(data) end
	self._onupdate_shieldbg = function(source, data) self:OnUpdateShieldBackground(data) end
	self._do_hide = function(source, data) self:Hide() end
	self._do_show = function(source, data) self:Show() end

	self:Hide()

	self:SetOwner(owner)
end)

function Gibberish_EnemyFollowHealthBar:UpdateShieldBGSize()
	local new_w, new_h = self.hp_bar:GetSize()
	print("UpdateShieldBGSize")
	print(new_w, new_h)
	self.shield_hp_border:SetSize(new_w + 10 * HACK_FOR_4K, new_h + 10)
		:LayoutBounds("center", "center", self.hp_bar)
		:Offset(0, -28)
end

function Gibberish_EnemyFollowHealthBar:_RefreshColor()
	self.hp_bar:RefreshColor()
end

function Gibberish_EnemyFollowHealthBar:OnUpdatePower(data)
	local is_shield = false

	local shield_def = Power.Items.SHIELD.shield
	if data.power_def == shield_def then
		is_shield = true
	end

	if is_shield then
		self.time_visible = self.time_visible_shield
		self:Reveal()
	end
end

function Gibberish_EnemyFollowHealthBar:OnAddPower(data)
	local is_shield = false
	if data.def ~= nil and data.def.tags ~= nil then
		for i, tag in ipairs(data.def.tags) do
			if tag == POWER_TAGS.PROVIDES_SHIELD then
				is_shield = true
				break
			end
		end
	end

	if is_shield then
		self.time_visible = self.time_visible_shield
		self:Reveal()
	end
end

function Gibberish_EnemyFollowHealthBar:OnUpdateShieldBackground(data)
	if data.enabled then
		self.shield_hp_border:AlphaTo(1, data.dont_animate and 0 or .4, easing.inExpo)
	else
		self.shield_hp_border:AlphaTo(0, data.dont_animate and 0 or .4, easing.outExpo)
	end
end

function Gibberish_EnemyFollowHealthBar:OnEnterRoom(data)
	local should_reveal = false
	if self.owner:HasTag(POWER_TAGS.PROVIDES_SHIELD) or
		self.owner.components.health:IsLow() then
		should_reveal = true
	end

	if should_reveal then
		self:Reveal()
	end
end

function Gibberish_EnemyFollowHealthBar:SetOwner(owner)
	if owner ~= self.owner then
		if self.owner ~= nil then
			self.inst:RemoveEventCallback("death", self._ondeath, self.owner)
			self.inst:RemoveEventCallback("onremove", self._onremovetarget, self.owner)
			self.inst:RemoveEventCallback("maxhealthchanged", self._onmaxhealthchanged, self.owner)
			self.inst:RemoveEventCallback("healthchanged", self._onhealthchanged, self.owner)
			self.inst:RemoveEventCallback("power_stacks_changed", self._onupdate_power, self.owner)
			self.inst:RemoveEventCallback("update_ui_color", self._onupdate_ui_color, self.owner)
			self.inst:RemoveEventCallback("add_power", self._onadd_power, owner)
			self.inst:RemoveEventCallback("shield_ui_bg_update", self._onupdate_shieldbg, owner)
			self.inst:RemoveEventCallback("enemyfollowhealthbar_hide", self._do_hide, self.owner)
			self.inst:RemoveEventCallback("enemyfollowhealthbar_show", self._do_show, self.owner)
		end

		self.owner = owner

		if self.owner ~= nil then
			self.inst:ListenForEvent("death", self._ondeath, self.owner)
			self.inst:ListenForEvent("onremove", self._onremovetarget, self.owner)
			self.inst:ListenForEvent("maxhealthchanged", self._onmaxhealthchanged, self.owner)
			self.inst:ListenForEvent("healthchanged", self._onhealthchanged, self.owner)
			self.inst:ListenForEvent("power_stacks_changed", self._onupdate_power, self.owner)
			self.inst:ListenForEvent("update_ui_color", self._onupdate_ui_color, self.owner)
			self.inst:ListenForEvent("add_power", self._onadd_power, self.owner)
			self.inst:ListenForEvent("shield_ui_bg_update", self._onupdate_shieldbg, self.owner)
			self.inst:ListenForEvent("enemyfollowhealthbar_hide", self._do_hide, self.owner)
			self.inst:ListenForEvent("enemyfollowhealthbar_show", self._do_show, self.owner)
		end
		self.hp_bar:SetOwner(self.owner)
	end

	
	if self.always_shown then
		owner:DoTaskInTime(0, function()
			self:Reveal()
		end)
	end
end

function Gibberish_EnemyFollowHealthBar:Reveal()
	self:ShowHealthBar()
end

function Gibberish_EnemyFollowHealthBar:ShowHealthBar()
	self:UpdatePosition()
	self:Show()
	self:StartUpdating()

	self.container:AlphaTo(1, 0.1, easing.inExpo)

	if not self.always_shown then
		self:MakeFadeOutTask()
	end
end

function Gibberish_EnemyFollowHealthBar:MakeFadeOutTask()
	if self._fade_out_task then
		self._fade_out_task:Cancel()
		self._fade_out_task = nil
	end

	self._fade_out_task = self.inst:DoTaskInTime(self.time_visible, function()
		self.container:AlphaTo(0, self.fade_out_time, easing.inExpo, function()
			self:StopUpdating()
			self:Hide()
		end)
	end)
end

function Gibberish_EnemyFollowHealthBar:UpdatePosition()
	local x, y = self:CalcLocalPositionFromEntity(self.owner)
	self:SetPosition(x, y + Y_OFFSET)
end

function Gibberish_EnemyFollowHealthBar:OnUpdate(dt)
	if self.owner ~= nil and self.owner:IsValid() then
		self:UpdatePosition()
	else
		self:Remove()
	end
end

return Gibberish_EnemyFollowHealthBar
