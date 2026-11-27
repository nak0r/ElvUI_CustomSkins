local E, L, V, P, G = unpack(ElvUI)
local CustomSkins = E.CustomSkins
if not CustomSkins then return end

local function LoadExampleSkin(self, event, addon)
	if addon ~= "ExampleAddonName" then return end

	local frame = _G.ExampleAddonMainFrame
	if not frame or frame.isSkinned then return end

	-- 'self' inside an AS:RegisterSkin callback is the AddOnSkins (AS) instance
	if self.SkinFrame then
		self:SkinFrame(frame)
	else
		frame:SetTemplate("Transparent")
	end

	if _G.ExampleAddonCloseButton and self.SkinCloseButton then
		self:SkinCloseButton(_G.ExampleAddonCloseButton)
	end

	frame.isSkinned = true
end

-- Registers 'ExampleAddonName' into ElvUI_AddOnSkins and creates its checkbox automatically
CustomSkins:AddSkin("ExampleAddonName", LoadExampleSkin, "ADDON_LOADED")