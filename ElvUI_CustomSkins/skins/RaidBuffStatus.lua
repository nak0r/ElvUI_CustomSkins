-- ElvUI_AddOnSkins skin for RaidBuffStatus (WoW 3.3.5)
-- Same loading style as MarketWatcher.lua / EnhancedStackSplit.lua: self-contained, own events.
-- RaidBuffStatus is loaded late (often on demand by AddonLoader), so we wait for it and then
-- poll briefly until its frames exist.
--
-- Skins: dashboard (RBSFrame), talents window, options window, all text buttons, the
-- corner arrow buttons, dashboard + option icon buttons, check/radio boxes and the status bars.
-- Adds small Scale / Opacity sliders under the dashboard (saved in the RBS profile).
-- Not skinned: the class/role/spec icons inside the talents window rows.

local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local skinned = false
RaidBuffStatus_SkinLoaded = true -- debug flag: file was loaded

-- ---------------------------------------------------------------------------
-- Window scale (1 = original size). Icons, buttons and bars scale with their window.
-- (DASHBOARD_SCALE is only the starting value; the slider's saved value wins once used)
-- ---------------------------------------------------------------------------
local DASHBOARD_SCALE = 1.3  -- the main RBS dashboard
local TALENTS_SCALE   = 1.0  -- talent specialisations window
local OPTIONS_SCALE   = 1.0  -- buff options window

-- ---------------------------------------------------------------------------
-- Window transparency (background opacity)
--   1.0 = fully opaque, 0.0 = fully see-through, nil = use ElvUI's default transparency
-- Only the background is affected; borders, icons and text stay solid.
-- (DASHBOARD_ALPHA is only the starting value; the slider's saved value wins once used)
-- ---------------------------------------------------------------------------
local DASHBOARD_ALPHA = 1.0  -- the main RBS dashboard
local TALENTS_ALPHA   = 1.0  -- talent specialisations window
local OPTIONS_ALPHA   = nil  -- buff options window (nil = ElvUI default)

-- ---------------------------------------------------------------------------
-- Border colour
--   "custom" = one solid colour that you choose below (BORDER_R/G/B)
--   "class"  = your class colour
--   "elvui"  = leave the borders to ElvUI / ElvUI_AddOnSkins (their default colours)
-- ---------------------------------------------------------------------------
local BORDER_MODE = "elvui"
local BORDER_R, BORDER_G, BORDER_B = 0.7, 0.7, 0.7  -- the "custom" colour (light gray)

-- Talents window
local TALENT_ICON_SIZE = 20   -- icon size (the addon's own default in this copy is 30)
local TALENT_ROW_GAP   = 6    -- space between rows (pixels); the divider line sits in the middle of it
local TALENT_DIVIDERS  = true -- thin horizontal line between the entries
local TALENT_ICON_GAP  = 1    -- gap between the specialisation icons on the right (they start at the left of their column)

-- Font size of the "RBS v3.xxx" title on the dashboard
local TITLE_FONT_SIZE = 10

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local MODE = string.lower(tostring(BORDER_MODE))
if MODE ~= "class" and MODE ~= "elvui" then MODE = "custom" end

-- The colour for borders and for the thin accents the skin draws itself (divider lines, fallback arrows)
local function GetBorderColor()
	if MODE == "class" then
		local c = RAID_CLASS_COLORS[E.myclass or select(2, UnitClass("player"))]
		if c then return c.r, c.g, c.b end
	elseif MODE == "elvui" then
		local c = E.media and E.media.bordercolor
		if c then return c[1], c[2], c[3] end
	end
	return BORDER_R, BORDER_G, BORDER_B
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

-- Fallback only: draws a small down arrow (5 stacked 1px rows) if ElvUI's own arrow
-- skinning is not available.
local function AddArrow(btn)
	local px = E.mult or 1
	for i = 1, 5 do
		local t = btn:CreateTexture(nil, "OVERLAY")
		t:SetTexture("Interface\\Buttons\\WHITE8X8")
		t:SetHeight(px)
		t:SetWidth(px * (11 - 2 * i)) -- 9, 7, 5, 3, 1
		t:SetPoint("CENTER", btn, "CENTER", 0, (3 - i) * px)
		t:SetVertexColor(GetBorderColor())
	end
end

local function SkinTextButton(b)
	if b.rbsSkinned then return end
	b.rbsSkinned = true
	S:HandleButton(b, true)
	ColorBorderPersistent(b)
end

local function SkinCheck(b)
	if b.rbsSkinned then return end
	b.rbsSkinned = true
	if S.HandleCheckBox then
		S:HandleCheckBox(b)
		if b.backdrop then ColorBorder(b.backdrop) end
	end
end

-- Spell / item icon buttons: ElvUI-style bordered icon
local function SkinIconButton(b)
	if b.rbsSkinned then return end
	b.rbsSkinned = true
	if b.SetTemplate then b:SetTemplate("Default") end
	if b.StyleButton then b:StyleButton() end
	ColorBorder(b)
	b:HookScript("OnShow", ColorBorder)

	local function FixIcon()
		local t = b:GetNormalTexture()
		if t then
			t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			t:ClearAllPoints()
			t:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
			t:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
		end
	end
	FixIcon()
	-- the addon calls SetNormalTexture again whenever it re-uses a button
	hooksecurefunc(b, "SetNormalTexture", FixIcon)
end

-- Status bars (Raid Health etc.): thin ElvUI outline behind the existing bar
local function SkinBar(data)
	local barframe = data.barframe
	if not barframe or barframe.rbsSkinned then return end
	barframe.rbsSkinned = true
	local bd = CreateFrame("Frame", nil, barframe)
	bd:SetFrameLevel(math.max(barframe:GetFrameLevel() - 1, 0))
	bd:SetPoint("TOPLEFT", barframe, "TOPLEFT", -1, 1)
	bd:SetPoint("BOTTOMRIGHT", barframe, "BOTTOMRIGHT", 1, -1)
	bd:SetTemplate("Default")
end

-- ---------------------------------------------------------------------------
-- Skin
-- ---------------------------------------------------------------------------
local function Skin()
	if skinned then return end
	local RBS = RaidBuffStatus
	if not (RBS and RBS.frame and RBS.talentframe and RBS.optionsframe and RBS.SetFrameColours) then return end

	-- respect the AddOn Skins toggle if it exists and has been switched off
	if E.private and E.private.addOnSkins and E.private.addOnSkins.RaidBuffStatus == false then
		skinned = true
		return
	end
	skinned = true
	RaidBuffStatus_Skinned = true -- debug flag: skin function ran

	local frames = { RBS.frame, RBS.talentframe, RBS.optionsframe }

	-- 1) Window backdrops
	for _, frame in ipairs(frames) do
		if frame.StripTextures then frame:StripTextures() end
		frame:SetTemplate("Transparent")
		ColorBorderPersistent(frame)
	end

	-- the addon applies its own colour options to the windows (SetFrameColours);
	-- put the ElvUI colours back whenever it does
	-- background opacity per window (same order as the "frames" table above)
	local alphas = { DASHBOARD_ALPHA, TALENTS_ALPHA, OPTIONS_ALPHA }

	local function ReapplyColors()
		local c = E.media and E.media.backdropfadecolor or { 0.06, 0.06, 0.06, 0.8 }
		for i, frame in ipairs(frames) do
			local a = alphas[i]
			if type(a) ~= "number" then a = c[4] end
			a = math.max(0, math.min(1, a))
			frame:SetBackdropColor(c[1], c[2], c[3], a)
			-- always set here, even in "elvui" mode: the addon applies its own border colour to its windows
			frame:SetBackdropBorderColor(GetBorderColor())
		end
	end
	ReapplyColors()
	hooksecurefunc(RBS, "SetFrameColours", ReapplyColors)

	-- Dashboard title: smaller so it doesn't run into the Scan button
	local title = _G["RBSFrameTitle"]
	if title then
		local font, _, flags = title:GetFont()
		title:SetFont(font, TITLE_FONT_SIZE, flags)
	end

	-- Talents window: smaller icons, rows re-spaced to fit them, divider lines between the entries.
	-- (The addon sizes the icons with tfi.buttonsize but derives the row height from tfi.rowheight, and
	-- in this copy those don't match, so rows overlapped. The window height follows tfi.rowheight.)
	local tfi = RBS.tfi
	if tfi and tfi.rowframes then
		local size = TALENT_ICON_SIZE
		tfi.buttonsize = size
		tfi.rowheight = size + TALENT_ROW_GAP
		tfi.rowgap = 0
		local rowy = -tfi.topedge
		for i = 1, tfi.maxrows do
			local data = tfi.rowframes[i]
			local rowframe = data and data.rowframe
			if rowframe then
				rowframe:SetHeight(tfi.rowheight)
				rowframe:ClearAllPoints()
				rowframe:SetPoint("TOPLEFT", RBS.talentframe, "TOPLEFT", tfi.edge + tfi.inset, rowy)

				-- icons: resize, then place them. The column positions (tfi.classx etc.) are measured from the
				-- window's left edge, but the row frame already starts (edge + inset) in from it, so that
				-- offset has to be taken off again - otherwise the icons sit about 8px right of their column.
				local rowOffset = tfi.edge + tfi.inset
				for _, b in ipairs({ data.class, data.role, data.spec }) do b:SetSize(size, size) end
				for _, b in ipairs(data.specialisations or {}) do b:SetSize(size, size) end
				data.class:ClearAllPoints()
				data.class:SetPoint("TOPLEFT", rowframe, "TOPLEFT", tfi.classx - rowOffset + (tfi.classwidth - size) / 2, 0)
				data.role:ClearAllPoints()
				data.role:SetPoint("TOPLEFT", rowframe, "TOPLEFT", tfi.rolex - rowOffset + (tfi.rolewidth - size) / 2, 0)
				data.spec:ClearAllPoints()
				data.spec:SetPoint("TOPLEFT", rowframe, "TOPLEFT", tfi.specx - rowOffset + (tfi.specwidth - size) / 2, 0)

				-- specialisation icons: start at the left of their column and grow to the right
				-- (the addon builds them from the right edge towards the left)
				local specs = data.specialisations
				if specs and specs[1] then
					specs[1]:ClearAllPoints()
					specs[1]:SetPoint("TOPLEFT", rowframe, "TOPLEFT", tfi.specialisationsx - rowOffset + 2, 0)
					for j = 2, #specs do
						specs[j]:ClearAllPoints()
						specs[j]:SetPoint("TOPLEFT", specs[j - 1], "TOPRIGHT", TALENT_ICON_GAP, 0)
					end
				end

				-- player name: vertically centred on the icons
				if data.name then
					data.name:ClearAllPoints()
					data.name:SetPoint("LEFT", rowframe, "LEFT", 0, TALENT_ROW_GAP / 2)
				end

				-- divider above every row except the first (so it only appears between entries)
				if TALENT_DIVIDERS and i > 1 and not rowframe.rbsDivider then
					local line = rowframe:CreateTexture(nil, "ARTWORK")
					line:SetTexture("Interface\\Buttons\\WHITE8X8")
					line:SetHeight(E.mult or 1)
					line:SetPoint("TOPLEFT", rowframe, "TOPLEFT", -tfi.inset, TALENT_ROW_GAP / 2)
					line:SetPoint("TOPRIGHT", rowframe, "TOPRIGHT", tfi.inset, TALENT_ROW_GAP / 2)
					local r, g, b = GetBorderColor()
					line:SetVertexColor(r, g, b, 0.5)
					rowframe.rbsDivider = line
				end

				rowy = rowy - tfi.rowheight - tfi.rowgap
			end
		end
		if RBS.talentframe:IsVisible() then RBS:UpdateTalentsFrame() end -- recalculates the window height
	end

	-- Window scale
	RBS.frame:SetScale(DASHBOARD_SCALE)
	RBS.talentframe:SetScale(TALENTS_SCALE)
	RBS.optionsframe:SetScale(OPTIONS_SCALE)

	-- The addon saves/loads the dashboard position in a way that drifts once the frame is
	-- scaled (it mixes the frame's own units with UIParent units). These replacements store
	-- the same values as the original for an unscaled frame, so saved positions stay valid.
	function RBS:SaveFramePosition()
		local scale = self.frame:GetScale()
		self.db.profile.x = self.frame:GetLeft() * scale
		self.db.profile.y = self.frame:GetTop() * scale - UIParent:GetTop()
	end
	function RBS:LoadFramePosition()
		local frame = self.frame
		local scale = frame:GetScale()
		local x, y = self.db.profile.x, self.db.profile.y
		frame:ClearAllPoints()
		if x ~= 0 or y ~= 0 then
			frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x / scale, y / scale)
		else
			frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		end
	end
	RBS:LoadFramePosition()

	-- ------------------------------------------------------------------
	-- Scale / opacity sliders under the dashboard (values saved in the RBS profile)
	-- ------------------------------------------------------------------
	local prof = RBS.db and RBS.db.profile
	if prof then
		-- restore saved values
		if type(prof.skinScale) == "number" then
			DASHBOARD_SCALE = prof.skinScale
			RBS:SaveFramePosition()          -- uses the current (old) scale
			RBS.frame:SetScale(DASHBOARD_SCALE)
			RBS:LoadFramePosition()          -- re-places it using the new scale
		end
		if type(prof.skinAlpha) == "number" then
			alphas[1] = prof.skinAlpha
			ReapplyColors()
		end

		-- small gear button on the right side of the dashboard, just under the options arrow
		local toggle = CreateFrame("Button", "RBSSkinSliderToggle", RBS.frame)
		toggle.rbsSkinned = true
		toggle:SetSize(12, 12)
		if RBS.optionsbutton then
			toggle:SetPoint("RIGHT", RBS.optionsbutton, "LEFT", -2, 0)
		else
			toggle:SetPoint("TOPRIGHT", RBS.frame, "TOPRIGHT", -6, -30)
		end
		toggle:SetTemplate("Default")
		toggle:StyleButton()
		local gear = toggle:CreateTexture(nil, "ARTWORK")
		gear:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
		gear:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		gear:SetPoint("TOPLEFT", toggle, "TOPLEFT", 1, -1)
		gear:SetPoint("BOTTOMRIGHT", toggle, "BOTTOMRIGHT", -1, 1)
		ColorBorderPersistent(toggle)

		-- tooltip
		toggle:HookScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("Scale / Opacity")
			GameTooltip:Show()
		end)
		toggle:HookScript("OnLeave", function() GameTooltip:Hide() end)

		-- the popout panel opens directly beside the gear button (to its right)
		local bar = CreateFrame("Frame", nil, RBS.frame)
		bar:SetSize(130, 74)
		bar:SetPoint("TOPLEFT", toggle, "TOPRIGHT", 6, 0)
		bar:SetFrameStrata("DIALOG")
		bar:SetTemplate("Transparent")
		ColorBorder(bar)

		if prof.skinPanelOpen == nil then prof.skinPanelOpen = false end -- closed by default
		if prof.skinPanelOpen then bar:Show() else bar:Hide() end
		toggle:SetScript("OnClick", function()
			prof.skinPanelOpen = not prof.skinPanelOpen
			if prof.skinPanelOpen then bar:Show() else bar:Hide() end
		end)

		local function MakeSlider(name, label, minv, maxv, step, fmt, value, onChange, onRelease)
			local s = CreateFrame("Slider", name, bar, "OptionsSliderTemplate")
			s:SetHeight(10)
			s:SetMinMaxValues(minv, maxv)
			s:SetValueStep(step)
			_G[name .. "Low"]:SetText("")
			_G[name .. "High"]:SetText("")
			local text = _G[name .. "Text"]
			local font, _, flags = text:GetFont()
			text:SetFont(font, 9, flags)

			local init = true
			s:SetValue(value)
			text:SetText(label .. ": " .. string.format(fmt, value))

			if S.HandleSliderFrame then S:HandleSliderFrame(s) end

			s:SetScript("OnValueChanged", function(self, v)
				v = math.floor(v / step + 0.5) * step
				text:SetText(label .. ": " .. string.format(fmt, v))
				if init then return end
				onChange(v, self.dragging)
			end)
			s:HookScript("OnMouseDown", function(self) self.dragging = true end)
			s:HookScript("OnMouseUp", function(self)
				self.dragging = false
				onRelease(math.floor(self:GetValue() / step + 0.5) * step)
			end)
			init = false
			return s
		end

		-- Opacity: applied live
		local aSlider = MakeSlider("RBSSkinAlphaSlider", "Opacity", 0, 1, 0.05, "%.2f",
			(type(alphas[1]) == "number") and alphas[1] or (E.media.backdropfadecolor and E.media.backdropfadecolor[4]) or 0.8,
			function(v)
				alphas[1] = v
				prof.skinAlpha = v
				ReapplyColors()
			end,
			function() end)

		-- Scale: applied when the mouse is released (scaling while dragging makes the slider jump
		-- under the cursor, because the slider scales together with the window)
		local sSlider = MakeSlider("RBSSkinScaleSlider", "Scale", 0.6, 2.0, 0.05, "%.2f",
			RBS.frame:GetScale(),
			function(v, dragging)
				if dragging then return end
				-- (mouse wheel / keyboard changes) fall through to the same apply
				RBS:SaveFramePosition()
				RBS.frame:SetScale(v)
				RBS:LoadFramePosition()
				prof.skinScale = v
			end,
			function(v)
				RBS:SaveFramePosition()
				RBS.frame:SetScale(v)
				RBS:LoadFramePosition()
				prof.skinScale = v
				RBS:SaveFramePosition()
			end)

		sSlider:SetPoint("TOPLEFT", bar, "TOPLEFT", 10, -22)
		sSlider:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -10, -22)
		aSlider:SetPoint("TOPLEFT", bar, "TOPLEFT", 10, -54)
		aSlider:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -10, -54)
	end

	-- ------------------------------------------------------------------
	-- Small button beside the left arrow: opens Interface > AddOns > RaidBuffStatus
	-- ------------------------------------------------------------------
	do
		local cfg = CreateFrame("Button", "RBSSkinConfigButton", RBS.frame)
		cfg.rbsSkinned = true
		cfg:SetSize(12, 12)
		if RBS.talentsbutton then
			cfg:SetPoint("LEFT", RBS.talentsbutton, "RIGHT", 2, 0)
		else
			cfg:SetPoint("TOPLEFT", RBS.frame, "TOPLEFT", 30, -8)
		end
		cfg:SetTemplate("Default")
		cfg:StyleButton()
		local icon = cfg:CreateTexture(nil, "ARTWORK")
		icon:SetTexture("Interface\\Icons\\INV_Misc_Wrench_01")
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		icon:SetPoint("TOPLEFT", cfg, "TOPLEFT", 1, -1)
		icon:SetPoint("BOTTOMRIGHT", cfg, "BOTTOMRIGHT", -1, 1)
		ColorBorderPersistent(cfg)

		cfg:HookScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:SetText("RaidBuffStatus configuration")
			GameTooltip:Show()
		end)
		cfg:HookScript("OnLeave", function() GameTooltip:Hide() end)

		cfg:SetScript("OnClick", function()
			-- the interface options window opens on the wrong page the first time in 3.3.5, so call twice
			InterfaceOptionsFrame_OpenToCategory("RaidBuffStatus")
			InterfaceOptionsFrame_OpenToCategory("RaidBuffStatus")
		end)
	end

	-- 2) Corner arrow buttons on the dashboard (talents / options)
	for _, b in ipairs({ RBS.talentsbutton, RBS.optionsbutton }) do
		if b and not b.rbsSkinned then
			b.rbsSkinned = true
			-- ElvUI's own arrow-button skin (pointing down), same as other ElvUI arrow buttons
			local ok = S.HandleNextPrevButton and pcall(S.HandleNextPrevButton, S, b, "down")
			if not ok then
				S:HandleButton(b, true)
				AddArrow(b)
			end
			ColorBorderPersistent(b)
		end
	end

	-- 3) Everything that sits directly on the three windows
	local function ScanWindow(frame, isDashboard)
		for _, child in ipairs({ frame:GetChildren() }) do
			local otype = child:GetObjectType()
			if otype == "CheckButton" then
				SkinCheck(child)
			elseif otype == "Button" then
				local text = child:GetText()
				if text and text ~= "" then
					SkinTextButton(child)          -- Boss, Trash, R, Scan, Okay, Refresh, ...
				elseif isDashboard then
					if child.count then SkinIconButton(child) end  -- dashboard buff icons (bars have no .count)
				else
					SkinIconButton(child)           -- icons in the options window
				end
			end
		end
	end

	-- 4) Rescan for buttons and bars the addon creates later (when options change)
	local function Rescan()
		ScanWindow(RBS.frame, true)
		if RBS.bars then
			for _, data in pairs(RBS.bars) do SkinBar(data) end
		end
	end

	ScanWindow(RBS.talentframe, false)
	ScanWindow(RBS.optionsframe, false)
	Rescan()

	hooksecurefunc(RBS, "AddBuffButtons", Rescan)
	hooksecurefunc(RBS, "CreateBar", Rescan)
end

-- ---------------------------------------------------------------------------
-- Wait for the addon (it may load on demand, long after login)
-- ---------------------------------------------------------------------------
local waited = 0
local function Poll(self, elapsed)
	waited = waited + elapsed
	if waited < 0.2 then return end
	waited = 0
	local RBS = RaidBuffStatus
	if RBS and RBS.frame and RBS.talentframe and RBS.optionsframe and RBS.SetFrameColours then
		self:SetScript("OnUpdate", nil)
		Skin()
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, arg1)
	if skinned then return end
	if event == "ADDON_LOADED" and arg1 ~= "RaidBuffStatus" then return end
	if event == "PLAYER_LOGIN" and not IsAddOnLoaded("RaidBuffStatus") then return end
	self:SetScript("OnUpdate", Poll)
end)