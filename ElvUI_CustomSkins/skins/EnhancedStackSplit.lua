-- ElvUI_AddOnSkins skin for EnhancedStackSplit (WoW 3.3.5)
-- Same loading style as MarketWatcher.lua: runs on its own events, no skin-callback API.
-- (ElvUI_AddOnSkins loads BEFORE EnhancedStackSplit alphabetically, so the addon's
--  frames don't exist yet when this file runs - we wait for PLAYER_LOGIN instead.)
--
-- The skin detects which build of EnhancedStackSplit is installed and adapts:
--   "original" : stock addon (XL toggle button; XL buttons 10 12 14 15 16 20 + 100)
--   "modified" : fixed-layout build (buttons 10 20 40 50 100, XL toggle disabled,
--                empty placeholder buttons 14-16)
--   "generic"  : anything else - the skin just lays out whatever buttons are visible
--
-- In every case the expanded layout is used and the XL toggle button is removed.

local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local skinned = false
EnhancedStackSplit_SkinLoaded = true -- debug flag: file was loaded

-- Set to true to print which addon version was detected when the skin runs.
local DEBUG = false

-- ---------------------------------------------------------------------------
-- Border colour:
--   "class"  = your class colour
--   "custom" = one solid colour that you choose (BORDER_R/G/B below)
--   "elvui"  = leave the borders to ElvUI / ElvUI_AddOnSkins (their default colours)
-- ---------------------------------------------------------------------------
local BORDER_MODE = "class"
local BORDER_R, BORDER_G, BORDER_B = 0.7, 0.7, 0.7  -- the "custom" colour (light gray)

-- ---------------------------------------------------------------------------
-- Layout constants (distances are measured up from the bottom of StackSplitFrame)
-- ---------------------------------------------------------------------------
local BTN_H   = 20   -- height of the numbered / control buttons
local MAIN_H  = 22   -- height of Okay / Cancel / "1" (auto mode)
local GAP     = 2    -- gap between neighbouring buttons
local MAIN_Y  = 36   -- vertical centre of the Okay / Cancel row
local ROW1_TOP  = 21 -- top edge of the first row of buttons (2-9)
local ROW_PITCH = 23 -- distance from one row of buttons to the next
local BG_PADDING = 5 -- space between the last row of buttons and the bottom of the backdrop
local MAX_BUTTONS = 24 -- numbered buttons are checked up to this index

-- Amounts whose button should be removed, e.g. { ["100"] = true } to drop the 100 button.
-- Empty by default: the skin lays out whichever buttons this version of the addon shows.
local HIDDEN_AMOUNTS = {}

-- ---------------------------------------------------------------------------
-- Version detection
-- ---------------------------------------------------------------------------
-- Per-version behaviour:
--   forceXL : make sure the addon is in expanded (XL) mode (only the stock addon has one)
local PROFILES = {
	original = { name = "original",  forceXL = true  },
	modified = { name = "modified",  forceXL = false },
	generic  = { name = "generic",   forceXL = false },
}

local function ButtonText(i)
	local b = _G["EnhancedStackSplitButton" .. i]
	return b and b:GetText() or nil
end

-- Looks at the fixed labels of buttons 11-16 (the stock addon never re-texts those):
--   stock : 10 12 14 15 16 20
--   mod   : 40 50 100 + empty placeholders
local function DetectVersion()
	local seen = {}
	for i = 11, 16 do
		local t = ButtonText(i)
		if t and t ~= "" then seen[t] = true end
	end
	if seen["12"] or seen["14"] or seen["15"] or seen["16"] then return PROFILES.original end
	if seen["40"] or seen["50"] then return PROFILES.modified end
	return PROFILES.generic
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- Expanded mode is always on. Done early (ADDON_LOADED) so the stock addon builds its
-- frames in expanded mode. (The fixed-layout build ignores this setting.)
local function ForceExpanded()
	EnhancedStackSplit_Options = EnhancedStackSplit_Options or {}
	EnhancedStackSplit_Options.XLmode = true
end

local function HideTextures(frame)
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == "Texture" then
			region:SetTexture(nil)
			region:Hide()
		end
	end
end

-- Border colour
local MODE = string.lower(tostring(BORDER_MODE))
if MODE ~= "custom" and MODE ~= "elvui" then MODE = "class" end

local function GetBorderColor()
	if MODE == "custom" then
		return BORDER_R, BORDER_G, BORDER_B
	elseif MODE == "elvui" then
		local c = E.media and E.media.bordercolor
		if c then return c[1], c[2], c[3] end
	end
	local c = RAID_CLASS_COLORS[E.myclass or select(2, UnitClass("player"))]
	if c then return c.r, c.g, c.b end
	return 1, 0.82, 0
end

-- In "elvui" mode the skin does not recolour anything: ElvUI's own border colour stays
local function ColorBorder(frame)
	if MODE == "elvui" then return end
	if not frame or not frame.SetBackdropBorderColor then return end
	frame:SetBackdropBorderColor(GetBorderColor())
end

local function ColorBorderPersistent(frame)
	-- ElvUI buttons reset their border colour on mouse leave, so re-apply it
	if MODE == "elvui" then return end
	ColorBorder(frame)
	frame:HookScript("OnLeave", ColorBorder)
	frame:HookScript("OnShow", ColorBorder)
end

-- ---------------------------------------------------------------------------
-- Skin
-- ---------------------------------------------------------------------------
local function SkinEnhancedStackSplit()
	if skinned then return end
	if not StackSplitFrame or not EnhancedStackSplitTopTextureFrame then return end

	-- respect the AddOn Skins toggle if it exists and has been switched off
	if E.private and E.private.addOnSkins and E.private.addOnSkins.EnhancedStackSplit == false then
		skinned = true
		return
	end
	skinned = true
	EnhancedStackSplit_Skinned = true -- debug flag: skin function ran

	-- which build of the addon is this?
	local profile = DetectVersion()
	EnhancedStackSplit_SkinVersion = profile.name -- debug flag: detected version
	if DEBUG then
		print("|cff33ff99EnhancedStackSplit skin:|r detected '" .. profile.name .. "' version")
	end

	-- Stock addon only: if expanded mode didn't get switched on before the frames were
	-- built (event order), flip it now by "clicking" the addon's own XL toggle.
	if profile.forceXL then
		local wasXL = EnhancedStackSplit_Options and EnhancedStackSplit_Options.XLmode
		ForceExpanded()
		if not wasXL and EnhancedStackSplitXLModeButton and EnhancedStackSplitXLModeButton:GetScript("OnClick") then
			-- the toggle flips XLmode, so put it back to false first
			EnhancedStackSplit_Options.XLmode = false
			EnhancedStackSplitXLModeButton:Click()
		end
	end

	local SSF = StackSplitFrame

	-- Base frame: if ElvUI hasn't skinned it, at least remove the Blizzard art
	if not SSF.template then
		SSF:StripTextures()
	end

	-- 1) Remove the Blizzard MoneyFrame artwork the addon adds
	HideTextures(EnhancedStackSplitTopTextureFrame)
	HideTextures(EnhancedStackSplitBottomTextureFrame)
	HideTextures(EnhancedStackSplitBottom2TextureFrame)
	HideTextures(EnhancedStackSplitAutoTextureFrame) -- background + both alert icons

	-- 2) ONE backdrop for the whole thing (frame + button rows), so there is no seam
	--    where the stack split frame ends. It sits behind the frame's own content.
	local bg = CreateFrame("Frame", nil, SSF)
	bg:SetTemplate("Transparent")
	bg:SetFrameLevel(math.max(SSF:GetFrameLevel() - 1, 0))
	bg:SetPoint("TOPLEFT", SSF, "TOPLEFT", 0, 0)
	bg:SetPoint("TOPRIGHT", SSF, "TOPRIGHT", 0, 0)
	bg:SetHeight(SSF:GetHeight() + 50)
	ColorBorderPersistent(bg)

	-- hide the stack split frame's own backdrop (bg replaces it)
	local function HideBaseBackdrop()
		if SSF.SetBackdrop then SSF:SetBackdrop(nil) end
		if SSF.backdrop then SSF.backdrop:Hide() end
	end
	HideBaseBackdrop()
	SSF:HookScript("OnShow", HideBaseBackdrop)

	-- 3) Auto-split info panel: opaque backdrop so the number input underneath is covered
	local panel = EnhancedStackSplitAutoTextureFrame
	panel:SetTemplate("Default")
	ColorBorderPersistent(panel)
	-- keep the mode/info text above that panel
	EnhancedStackSplitTopTextureFrame:SetFrameLevel(panel:GetFrameLevel() + 1)

	-- Number input box (the dark box around the arrows and the amount). ElvUI's own
	-- stack split skin creates it as StackSplitFrame.bg1; fall back to searching for it.
	local inputBox = SSF.bg1
	if not inputBox then
		for _, child in ipairs({ SSF:GetChildren() }) do
			if child ~= bg and child ~= panel and child.template then
				local point, rel, _, x, y = child:GetPoint(1)
				if point == "TOPLEFT" and rel == SSF and x and y and math.abs(x - 10) < 3 and math.abs(y + 15) < 3 then
					inputBox = child
					break
				end
			end
		end
	end
	if inputBox then
		ColorBorderPersistent(inputBox)
	end

	-- 4) Buttons
	--    The numbered buttons are discovered, not hard-coded, so both builds work.
	--    Buttons with no label (the fixed-layout build's hidden 14-16 placeholders) are
	--    left alone - they never show.
	local lastIndex = 0
	local buttons = {
		"EnhancedStackSplitAuto1Button",
		"EnhancedStackSplitAutoSplitButton",
		"EnhancedStackSplitModeTXTButton",
	}
	for i = 1, MAX_BUTTONS do
		local b = _G["EnhancedStackSplitButton" .. i]
		if b then
			lastIndex = i
			local text = b:GetText()
			if text and text ~= "" then
				buttons[#buttons + 1] = "EnhancedStackSplitButton" .. i
			else
				b:Hide()
			end
		end
	end

	for _, name in ipairs(buttons) do
		local button = _G[name]
		if button then
			S:HandleButton(button, true)
			ColorBorderPersistent(button)
			-- The addon re-applies Blizzard textures to these parts whenever it
			-- enables/disables a button, so keep them invisible via alpha.
			for _, part in ipairs({ "Left", "Middle", "Right" }) do
				local tex = _G[name .. part]
				if tex then tex:SetAlpha(0) end
			end
		end
	end

	-- Blizzard Okay / Cancel (only if not skinned yet)
	if StackSplitOkayButton and not StackSplitOkayButton.template then
		S:HandleButton(StackSplitOkayButton)
	end
	if StackSplitOkayButton then ColorBorderPersistent(StackSplitOkayButton) end
	if StackSplitCancelButton and not StackSplitCancelButton.template then
		S:HandleButton(StackSplitCancelButton)
	end
	if StackSplitCancelButton then ColorBorderPersistent(StackSplitCancelButton) end

	-- XL toggle button: removed (expanded mode is always on). Both builds create it;
	-- the fixed-layout build already hides it, the stock one shows it.
	local xlb = EnhancedStackSplitXLModeButton
	if xlb then
		xlb:Hide()
		xlb.Show = E.noop -- stop anything from re-showing it
	end

	-- Auto-split info text: one line sits centred in the panel; while the hover preview
	-- (second line) is shown, both lines are centred around the middle of the panel
	-- (line 1 sits right above the centre, line 2 right below it).
	local function UpdateInfoText()
		local line1, line2 = EnhancedStackSplitTextAutoText1, EnhancedStackSplitTextAutoText2
		local t2 = line2:GetText()
		line1:ClearAllPoints()
		line2:ClearAllPoints()
		if t2 and t2 ~= "" then
			line1:SetPoint("BOTTOM", panel, "CENTER", 0, 0)
			line2:SetPoint("TOP", panel, "CENTER", 0, 0)
		else
			line1:SetPoint("CENTER", panel, "CENTER", 0, 0)
			line2:SetPoint("TOP", line1, "BOTTOM", 0, -1)
		end
	end
	hooksecurefunc(EnhancedStackSplitTextAutoText2, "SetText", UpdateInfoText)

	-- 5) Layout - re-positions everything so nothing overlaps.
	--    Row 1: 2-9 | next rows: every other visible amount, ascending | last row: [M][Auto]
	--      stock addon (XL):  10 12 14 15 16 20 100
	--      fixed-layout build: 10 20 40 50 100
	local function Layout()
		local W = SSF:GetWidth()

		local function btn(i) return _G["EnhancedStackSplitButton" .. i] end

		-- lays a list of buttons out in one centred row
		local function Row(list, w, top)
			local function widthOf(b) if type(w) == "function" then return w(b) end return w end
			local total = (#list - 1) * GAP
			for _, b in ipairs(list) do total = total + widthOf(b) end
			local x = math.floor((W - total) / 2)
			for _, b in ipairs(list) do
				local bw = widthOf(b)
				b:SetWidth(bw)
				b:SetHeight(BTN_H)
				b:ClearAllPoints()
				b:SetPoint("TOPLEFT", SSF, "BOTTOMLEFT", x, top)
				x = x + bw + GAP
			end
		end

		-- Okay / Cancel / auto-mode "1"
		local okay, cancel, auto1 = StackSplitOkayButton, StackSplitCancelButton, EnhancedStackSplitAuto1Button
		okay:SetHeight(MAIN_H)
		okay:ClearAllPoints()
		okay:SetPoint("RIGHT", SSF, "BOTTOM", -3, MAIN_Y)
		cancel:SetHeight(MAIN_H)
		cancel:ClearAllPoints()
		cancel:SetPoint("LEFT", SSF, "BOTTOM", 3, MAIN_Y)
		auto1:SetWidth(okay:GetWidth())
		auto1:SetHeight(MAIN_H)
		auto1:ClearAllPoints()
		auto1:SetPoint("RIGHT", SSF, "BOTTOM", -3, MAIN_Y)

		-- row 1: 2 - 9
		local r1 = {}
		for i = 1, 8 do
			local b = btn(i)
			if b then r1[#r1 + 1] = b end
		end
		local function RowTop(r) return ROW1_TOP - (r - 1) * ROW_PITCH end
		Row(r1, 18, RowTop(1))

		-- next rows: every other numbered button the addon is showing, in ascending order of
		-- the amount on the button. The addon's own show/hide state is respected; nothing is
		-- forced visible, so there are no empty buttons. (Sorting by amount rather than by
		-- on-screen position keeps the result identical on every open.)
		local extras, order = {}, {}
		for i = 9, lastIndex do
			local b = btn(i)
			if b then
				local text = b:GetText()
				if text and text ~= "" then
					if HIDDEN_AMOUNTS[text] then
						b:Hide()
					elseif b:IsShown() then
						extras[#extras + 1] = b
						order[b] = i
					end
				end
			end
		end
		table.sort(extras, function(x, y)
			local xn, yn = tonumber(x:GetText()) or 9999, tonumber(y:GetText()) or 9999
			if xn ~= yn then return xn < yn end
			return order[x] < order[y]
		end)
		-- a button is at least 24px wide, wider if its label needs it (e.g. "100")
		local function ExtraWidth(b)
			local fs = b:GetFontString()
			local tw = fs and fs:GetStringWidth() or 0
			return math.max(24, math.ceil(tw) + 10)
		end
		local available = W - 14
		local rowsUsed = 1
		local index = 1
		while index <= #extras do
			rowsUsed = rowsUsed + 1
			local chunk, used = {}, 0
			while index <= #extras do
				local need = ExtraWidth(extras[index]) + (#chunk > 0 and GAP or 0)
				if #chunk > 0 and used + need > available then break end
				chunk[#chunk + 1] = extras[index]
				used = used + need
				index = index + 1
			end
			Row(chunk, ExtraWidth, RowTop(rowsUsed))
		end
		local controlTop = RowTop(rowsUsed + 1)

		-- last row: [M][Auto] centred as a pair
		local modeBtn = EnhancedStackSplitModeTXTButton
		local autoBtn = EnhancedStackSplitAutoSplitButton
		modeBtn:SetHeight(BTN_H)
		autoBtn:SetHeight(BTN_H)
		local total = modeBtn:GetWidth() + GAP + autoBtn:GetWidth()
		modeBtn:ClearAllPoints()
		modeBtn:SetPoint("TOPLEFT", SSF, "BOTTOMLEFT", math.floor((W - total) / 2), controlTop)
		autoBtn:ClearAllPoints()
		autoBtn:SetPoint("TOPLEFT", modeBtn, "TOPRIGHT", GAP, 0)

		-- texts: mode label on top, the two info lines inside the auto-split panel
		EnhancedStackSplitTextFrameTXT:ClearAllPoints()
		EnhancedStackSplitTextFrameTXT:SetPoint("TOP", SSF, "TOP", 0, -1)

		panel:ClearAllPoints()
		panel:SetPoint("TOPLEFT", SSF, "TOPLEFT", 8, -14)
		panel:SetWidth(W - 16)
		panel:SetHeight(31)

		UpdateInfoText()

		-- backdrop height
		-- the backdrop reaches just past the last row (the [M][Auto] row)
		bg:SetHeight(SSF:GetHeight() + (BG_PADDING - (controlTop - BTN_H)))
	end

	Layout()

	-- The addon repositions things when a split frame opens. This hook is registered
	-- after the addon's own, so it runs after it.
	hooksecurefunc("OpenStackSplitFrame", Layout)
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == "EnhancedStackSplit" then
			ForceExpanded() -- before the addon builds its frames
		end
		return
	end
	SkinEnhancedStackSplit()
end)

-- Fallback: skin the first time a split frame opens
hooksecurefunc("OpenStackSplitFrame", SkinEnhancedStackSplit)