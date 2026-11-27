local E, L, V, P, G = unpack(ElvUI)

local CustomSkins = E:NewModule("ElvUI_CustomSkins", "AceEvent-3.0")
CustomSkins.skins = CustomSkins.skins or {}
E.CustomSkins = CustomSkins

local CUSTOM_SKIN_NAMES = {
	-- "ExampleAddonName",
	"MarketWatcher",
	"DressMe",
	"EnhancedStackSplit",
	"RaidBuffStatus",
}

local function GetSkinsDB()
	if E.private then
		E.private.addOnSkins = E.private.addOnSkins or {}
		return E.private.addOnSkins
	end
	if E.db then
		E.db.addOnSkins = E.db.addOnSkins or {}
		return E.db.addOnSkins
	end
end

local function ShowReloadPopup()
	if E.StaticPopup_Show then
		for _, popupName in ipairs({ "CONFIG_RL", "PRIVATE_RL", "ELVUI_RL" }) do
			if E.PopupDialogs and E.PopupDialogs[popupName] then
				E:StaticPopup_Show(popupName)
				return
			end
		end
		E:StaticPopup_Show("CONFIG_RL")
		return
	end
	if StaticPopup_Show then
		StaticPopup_Show("CONFIG_RL")
	end
end

function CustomSkins:AddSkin(addonName, skinFunc, ...)
	if type(addonName) ~= "string" then return end

	self.skins[addonName] = {
		func = skinFunc,
		events = { ... },
		applied = false,
	}

	local db = GetSkinsDB()
	if db and db[addonName] == nil then
		db[addonName] = true
	end
end

local function InjectCheckboxes()
	local optGroup = E.Options and E.Options.args and E.Options.args.addOnSkins
	local skinsGroup = optGroup and optGroup.args and optGroup.args.skins
	local targetArgs = skinsGroup and skinsGroup.args
	if not targetArgs then return end

	-- Remove stale ExampleAddonName entry if present
	if not CustomSkins.skins.ExampleAddonName then
		targetArgs.ExampleAddonName = nil
	end

	local baseOrder = 500
	targetArgs.ElvUI_CustomSkinsHeader = {
		type = "header",
		name = "|cff00b3ffElvUI_CustomSkins|r",
		order = baseOrder,
	}

	local sortedNames = {}
	for name in pairs(CustomSkins.skins) do
		sortedNames[#sortedNames + 1] = name
	end
	table.sort(sortedNames)

	for i, name in ipairs(sortedNames) do
		targetArgs[name] = {
			type = "toggle",
			name = name,
			desc = "Toggle " .. name .. " skin (ElvUI_CustomSkins).",
			order = baseOrder + i,
			get = function(info)
				local db = GetSkinsDB()
				local key = info[#info]
				if db and db[key] ~= nil then
					return db[key]
				end
				return true
			end,
			set = function(info, value)
				local db = GetSkinsDB()
				local key = info[#info]
				if db then
					db[key] = value and true or false
				end
				ShowReloadPopup()
			end,
		}
	end
end

function CustomSkins:ADDON_LOADED(_, loadedAddon)
	if loadedAddon == "ElvUI_OptionsUI" then
		InjectCheckboxes()
	end
end

function CustomSkins:PLAYER_ENTERING_WORLD()
	InjectCheckboxes()
end

function CustomSkins:Initialize()
	if self._initialized then return end
	self._initialized = true

	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	InjectCheckboxes()

	if E.ToggleOptionsUI and not self._hookedToggle then
		self._hookedToggle = true
		hooksecurefunc(E, "ToggleOptionsUI", InjectCheckboxes)
	end

	local AceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true)
	if AceConfigDialog and AceConfigDialog.SelectGroup and not self._hookedSelectGroup then
		self._hookedSelectGroup = true
		hooksecurefunc(AceConfigDialog, "SelectGroup", function(_, appName)
			if appName == "ElvUI" then
				InjectCheckboxes()
			end
		end)
	end
end

E:RegisterModule(CustomSkins:GetName())

if E.initialized then
	CustomSkins:Initialize()
end

for _, addonName in ipairs(CUSTOM_SKIN_NAMES) do
	CustomSkins:AddSkin(addonName)
end