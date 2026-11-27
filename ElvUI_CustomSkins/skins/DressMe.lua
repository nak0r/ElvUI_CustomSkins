-- ElvUI_AddOnSkins skin for DressMe (WoW 3.3.5 transmog addon)
-- Same loading style as the other skins in this folder: self-contained, own events.
-- (DressMe loads before ElvUI_AddOnSkins alphabetically, so its frames already exist
--  by the time this runs; we still wait for PLAYER_LOGIN to be safe.)
--
-- Skins: main window (backdrop, close button, tabs, bottom bar), the dressing room frame,
-- equipment slots + shadowform button, all text buttons, scroll bars, page slider,
-- dropdown menus, checkboxes, the saved/received lists, the character-window button and the
-- preview tiles in the "Items Preview" tab (flat borders; the selected tile keeps its purple border).

local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local skinned = false
DressMe_SkinLoaded = true -- debug flag: file was loaded

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------
-- Border colour:
--   "custom" = one solid colour that you choose (BORDER_R/G/B below)
--   "class"  = your class colour
--   "elvui"  = leave the borders to ElvUI / ElvUI_AddOnSkins (their default colours)
local BORDER_MODE = "elvui"
local BORDER_R, BORDER_G, BORDER_B = 0.7, 0.7, 0.7  -- the "custom" colour (light gray)
local SELECTED_R, SELECTED_G, SELECTED_B = 0.843, 0, 1  -- border of the selected slot (same purple as the selected preview tile)
local SELECTED_THICKNESS = 3                     -- border thickness (in pixels) of the selected slot
local HIGHLIGHT_ALPHA = 0.12                       -- strength of the white hover/selected overlay on slots (ElvUI default is 0.3)
local DROPDOWN_WIDTH  = 130                       -- width of the dropdown boxes
local DROPDOWN_HEIGHT = 22                        -- height of the dropdown boxes
local SUBCLASS_MENU_DOWN = 9                      -- moves the item type dropdown down so it lines up with the tabs

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local MODE = string.lower(tostring(BORDER_MODE))
if MODE ~= "class" and MODE ~= "elvui" then MODE = "custom" end

-- The colour for borders and for the thin lines the skin draws itself
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

local function HideTextures(frame)
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == "Texture" then
			region:SetTexture(nil)
			region:Hide()
		end
	end
end

local function SkinTextButton(b)
	if b.dmSkinned then return end
	b.dmSkinned = true
	S:HandleButton(b, true)
	ColorBorderPersistent(b)
end

local function SkinCheck(b)
	if b.dmSkinned then return end
	b.dmSkinned = true
	if S.HandleCheckBox then
		S:HandleCheckBox(b)
		if b.backdrop then ColorBorder(b.backdrop) end
	end
end

local function HideBorder(frame)
	if frame and frame.SetBackdropBorderColor then
		frame:SetBackdropBorderColor(0, 0, 0, 0)
	end
end

-- noBorder: remove the outline around the scroll bar's track (arrows and thumb keep theirs)
local function SkinScrollBar(bar, noBorder)
	if not bar or bar.dmSkinned then return end
	bar.dmSkinned = true
	if S.HandleScrollBar then S:HandleScrollBar(bar) end
	if noBorder then
		HideBorder(bar.trackbg)
		HideBorder(bar.backdrop)
		-- the track is a plain child frame of the slider (the arrow buttons are Buttons)
		for _, child in ipairs({ bar:GetChildren() }) do
			if child:GetObjectType() == "Frame" then HideBorder(child) end
		end
	end
end

-- opts.down        : move the whole dropdown down by this many pixels
-- opts.extendRight : draw the box starting at the dropdown's left edge and growing to the right
--                    (default: anchored to the arrow button and growing to the left)
-- opts.width       : box width (default DROPDOWN_WIDTH)
-- opts.anchorLabel : move the dropdown so its box starts opts.anchorX pixels to the right of this
--                    label's left edge (and vertically centred on it); used to line up columns
local function SkinDropDown(menu, opts)
	if not menu or menu.dmSkinned then return end
	menu.dmSkinned = true
	if not S.HandleDropDownBox then return end
	opts = opts or {}

	-- optional: put the dropdown next to a label, in a shared column
	if opts.anchorLabel then
		menu:ClearAllPoints()
		menu:SetPoint("LEFT", opts.anchorLabel, "LEFT", opts.anchorX or 0, -3)
	end

	-- optional: move the whole dropdown down (keeps its other anchors as they are)
	if opts.down and opts.down ~= 0 then
		local point, relativeTo, relativePoint, x, y = menu:GetPoint(1)
		if point then
			menu:SetPoint(point, relativeTo, relativePoint, x or 0, (y or 0) - opts.down)
		end
	end

	local name = menu:GetName()
	local button = name and _G[name .. "Button"]
	local text = name and _G[name .. "Text"]

	-- ElvUI picks the arrow direction from the button's name; a name containing "prev" (as in
	-- PreviewSetupMenu) gives a left arrow. Hide the name while ElvUI skins it so it stays a down arrow.
	if button then button.GetName = function() return "DressMeDropDownArrow" end end
	S:HandleDropDownBox(menu, menu:GetWidth())
	if button then button.GetName = nil end

	if not button then return end

	-- ElvUI's own box is not visible here, so draw one ourselves
	if menu.backdrop then menu.backdrop:Hide() end
	local box = CreateFrame("Frame", nil, menu)
	box:SetTemplate("Default")
	box:SetFrameLevel(math.max(menu:GetFrameLevel() - 1, 0))
	box:SetSize(opts.width or DROPDOWN_WIDTH, DROPDOWN_HEIGHT)
	if opts.extendRight then
		box:SetPoint("LEFT", menu, "LEFT", 4, 3)
		button:ClearAllPoints()
		button:SetPoint("RIGHT", box, "RIGHT", -2, 0)
	else
		box:SetPoint("RIGHT", button, "RIGHT", 2, 0)
	end
	ColorBorder(box)
	menu.dmBox = box

	-- clicking the label opens the menu too, like the original
	box:EnableMouse(true)
	box:SetScript("OnMouseDown", function() button:Click() end)

	-- label inside the box, left aligned, between the box edge and the arrow button
	if text then
		text:ClearAllPoints()
		text:SetPoint("LEFT", box, "LEFT", 6, 0)
		text:SetPoint("RIGHT", button, "LEFT", -2, 0)
		text:SetJustifyH("LEFT")
	end
end

local function Inset(tex, frame, pad)
	tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	tex:ClearAllPoints()
	tex:SetPoint("TOPLEFT", frame, "TOPLEFT", pad, -pad)
	tex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -pad, pad)
end

-- ItemButtonTemplate buttons used as equipment slots / the shadowform toggle.
-- The border and dark fill are drawn by a separate frame that sits BEHIND the button, so the
-- icon textures (which belong to the button itself) can never end up underneath ElvUI's backdrop.
-- hideAddonIcon: hide the addon's own icon texture(s) because the caller draws its own
local function SkinItemButton(btn, hideAddonIcon)
	if btn.dmSkinned then return end
	btn.dmSkinned = true

	-- keep the slot above the 3D model (same frame level as the model is a coin toss)
	local base = _G["DressMe"].dressingRoom:GetFrameLevel()
	btn:SetFrameLevel(base + 3)

	local bd = CreateFrame("Frame", nil, btn)
	bd:SetFrameLevel(base + 2)
	bd:SetAllPoints(btn)
	bd:SetTemplate("Default")
	ColorBorder(bd)
	btn.dmBorder = bd

	if btn.StyleButton then btn:StyleButton() end

	-- ElvUI's white overlay washes the icon out when a slot is selected (the addon "locks" the
	-- highlight on the selected slot). Make it very faint and show the selection with the border instead.
	local hl = btn:GetHighlightTexture()
	if hl then hl:SetTexture(1, 1, 1, HIGHLIGHT_ALPHA) end

	-- selection marker: a thick coloured border in its own frame above the icon, shown while the
	-- highlight is locked and hidden otherwise
	local sel = CreateFrame("Frame", nil, btn)
	sel:SetFrameLevel(base + 4)
	sel:SetAllPoints(btn)
	sel:SetBackdrop({
		edgeFile = E.media.blankTex,
		edgeSize = SELECTED_THICKNESS * (E.mult or 1),
	})
	sel:SetBackdropBorderColor(SELECTED_R, SELECTED_G, SELECTED_B)
	sel:Hide()
	btn.dmSelected = sel
	hooksecurefunc(btn, "LockHighlight", function() sel:Show() end)
	hooksecurefunc(btn, "UnlockHighlight", function() sel:Hide() end)

	-- the Blizzard quickslot border graphic
	local nt = btn:GetNormalTexture()
	if nt then
		nt:SetTexture(nil)
		nt:SetAlpha(0)
	end
	local ntName = btn:GetName() and _G[btn:GetName() .. "NormalTexture"]
	if ntName then ntName:SetAlpha(0) end

	-- icon textures the addon draws on the BACKGROUND layer: crop and inset them
	for _, region in ipairs({ btn:GetRegions() }) do
		if region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
			if hideAddonIcon then
				region:Hide()
			else
				Inset(region, btn, 1)
				region:SetDrawLayer("ARTWORK", 0)
			end
		end
	end
end

-- ---------------------------------------------------------------------------
-- Skin
-- ---------------------------------------------------------------------------
local function Skin()
	if skinned then return end
	local main = _G["DressMe"]
	if not (main and main.buttons and main.tabs and main.slots and main.dressingRoom) then return end

	-- respect the AddOn Skins toggle if it exists and has been switched off
	if E.private and E.private.addOnSkins and E.private.addOnSkins.DressMe == false then
		skinned = true
		return
	end
	skinned = true
	DressMe_Skinned = true -- debug flag: skin function ran

	-- 1) Main window: remove the GearManager artwork, use an ElvUI backdrop
	HideTextures(main)
	main:SetTemplate("Transparent")
	ColorBorderPersistent(main)

	-- thin vertical separator between the dressing room and the tab area (the original was artwork)
	local sep = main:CreateTexture(nil, "BORDER")
	sep:SetTexture("Interface\\Buttons\\WHITE8X8")
	sep:SetVertexColor(GetBorderColor())
	sep:SetWidth(1)
	sep:SetPoint("TOPLEFT", main, "TOPLEFT", 410, -72)
	sep:SetPoint("BOTTOM", main, "BOTTOM", 0, 32)

	-- 2) Bottom bar
	if main.stats then
		main.stats:SetTemplate("Transparent")
		ColorBorderPersistent(main.stats)
	end

	-- 3) Close button
	if main.buttons.close and S.HandleCloseButton then
		S:HandleCloseButton(main.buttons.close)
	end

	-- 4) Tabs
	local ourTabs = {}
	local function CenterTabText(tab)
		local text = tab:GetFontString() or (tab:GetName() and _G[tab:GetName() .. "Text"])
		if text then
			text:ClearAllPoints()
			text:SetPoint("CENTER", tab.backdrop or tab, "CENTER", 0, 0)
		end
	end
	for i = 1, 3 do
		local tab = main.buttons["tab" .. i]
		if tab and S.HandleTab then
			tab.dmSkinned = true
			S:HandleTab(tab)
			if tab.backdrop then ColorBorder(tab.backdrop) end
			ourTabs[tab] = true
			CenterTabText(tab)
		end
	end
	-- Blizzard's tab code moves the label up/down every time a tab is selected or deselected;
	-- put it back in the middle of the box afterwards
	local function OnTabChanged(tab)
		if ourTabs[tab] then CenterTabText(tab) end
	end
	hooksecurefunc("PanelTemplates_SelectTab", OnTabChanged)
	hooksecurefunc("PanelTemplates_DeselectTab", OnTabChanged)

	-- 5) Main dressing room: replace its Blizzard-style border with an ElvUI outline
	local dr = main.dressingRoom
	for _, child in ipairs({ dr:GetChildren() }) do
		if child:GetObjectType() == "Frame" and child.GetBackdrop and child:GetBackdrop() then
			child:SetBackdrop(nil)
		end
	end
	local drBorder = CreateFrame("Frame", nil, main)
	drBorder:SetTemplate("Default")
	drBorder:SetFrameLevel(math.max(dr:GetFrameLevel() - 1, 0))
	drBorder:SetPoint("TOPLEFT", dr, "TOPLEFT", -1, 1)
	drBorder:SetPoint("BOTTOMRIGHT", dr, "BOTTOMRIGHT", 1, -1)
	ColorBorderPersistent(drBorder)

	-- 6) Equipment slots and the shadowform button
	for _, slot in pairs(main.slots) do
		SkinItemButton(slot)
	end
	local shadowform = main.buttons.shadowform
	if shadowform then
		-- The shadowform icon is drawn by us: a plain icon texture that follows the button state
		-- (the addon's own icon texture is hidden), so it can't get lost behind the new backdrop.
		SkinItemButton(shadowform, true)
		local icon = shadowform:CreateTexture(nil, "ARTWORK")
		icon:SetDrawLayer("ARTWORK", -1) -- below the hover highlight
		Inset(icon, shadowform, 1)
		local function UpdateShadowformIcon()
			if main.dressingRoom.shadowformEnabled then
				icon:SetTexture("Interface\\Icons\\spell_nature_wispsplode")  -- "turn off" icon
			else
				icon:SetTexture("Interface\\Icons\\spell_shadow_shadowform")  -- "turn on" icon
			end
		end
		UpdateShadowformIcon()
		-- runs after the addon's own click handler, which flips the state
		shadowform:HookScript("OnClick", UpdateShadowformIcon)
		shadowform:HookScript("OnShow", UpdateShadowformIcon)
	end

	-- 7) Buttons stored by the addon
	for _, name in ipairs({ "send", "reset", "undress", "useTarget" }) do
		if main.buttons[name] then SkinTextButton(main.buttons[name]) end
	end

	-- 8) Items Preview tab: page slider and subclass dropdown
	local preview = main.tabs.preview
	SkinScrollBar(preview.slider, true)
	SkinDropDown(preview.subclassMenu, { down = SUBCLASS_MENU_DOWN })

	-- 8b) Preview tiles: flat ElvUI-style borders. The addon colours the border white normally and
	-- purple for the selected tile; white is mapped to our border colour, purple is left alone.
	local list = preview.list
	local listMeta = list and getmetatable(list)
	local frameMethods = listMeta and listMeta.__index
	local FrameSetBackdrop = type(frameMethods) == "table" and frameMethods.SetBackdrop
	if list and list.dressingRooms and FrameSetBackdrop then
		local flat = {
			bgFile = E.media.blankTex,
			edgeFile = E.media.blankTex,
			tile = false, tileSize = 0,
			edgeSize = E.mult or 1,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		}
		local function SkinTile(tile)
			if tile.dmSkinned then return end
			tile.dmSkinned = true
			FrameSetBackdrop(tile, flat) -- the original method; the tile's own override would resize the model
			tile:SetBackdropColor(0.25, 0.25, 0.25, 1)

			-- selected marker: thick border in its own frame above the model, same look as the selected slot
			local sel = CreateFrame("Frame", nil, tile)
			sel:SetFrameLevel(tile:GetFrameLevel() + 3)
			sel:SetAllPoints(tile)
			sel:SetBackdrop({
				edgeFile = E.media.blankTex,
				edgeSize = SELECTED_THICKNESS * (E.mult or 1),
			})
			sel:SetBackdropBorderColor(SELECTED_R, SELECTED_G, SELECTED_B)
			sel:Hide()
			tile.dmSelected = sel

			-- The addon colours the border white normally and purple when selected.
			-- White -> our border colour, purple -> thick selection border.
			local origSetBorder = tile.SetBackdropBorderColor
			tile.SetBackdropBorderColor = function(self, r, g, b, a)
				if type(r) == "table" or (r == 1 and g == 1 and b == 1) then
					sel:Hide()
					r, g, b = GetBorderColor()
				else
					sel:Show()
					r, g, b = SELECTED_R, SELECTED_G, SELECTED_B
				end
				origSetBorder(self, r, g, b, a)
			end

			-- the 3D model: much smaller gap now that the border is thin
			for _, child in ipairs({ tile:GetChildren() }) do
				if child:GetObjectType() == "DressUpModel" then
					child:ClearAllPoints()
					child:SetPoint("TOPLEFT", tile, "TOPLEFT", 2, -2)
					child:SetPoint("BOTTOMRIGHT", tile, "BOTTOMRIGHT", -2, 2)
				end
			end

			if list.selectedItemId ~= nil and tile.itemId == list.selectedItemId then
				tile:SetBackdropBorderColor(0.843, 0, 1) -- the addon's "selected" colour
			else
				tile:SetBackdropBorderColor(1, 1, 1)     -- mapped to our border colour
			end
		end
		local function SkinTiles()
			for _, tile in ipairs(list.dressingRooms) do SkinTile(tile) end
		end
		SkinTiles()
		-- tiles are created lazily, so check again whenever the list is laid out or refreshed
		hooksecurefunc(list, "SetupModel", SkinTiles)
		hooksecurefunc(list, "Update", SkinTiles)
	end

	-- 8c) Page scroll bar: make it exactly as tall as the tile rows (arrows included)
	local slider = preview.slider
	local upBtn = slider and slider.buttons and slider.buttons.up
	local downBtn = slider and slider.buttons and slider.buttons.down
	if list and list.dressingRooms and upBtn and downBtn then
		local function AlignSlider()
			local top, bottom
			for _, tile in ipairs(list.dressingRooms) do
				local tt, tb = tile:GetTop(), tile:GetBottom()
				if tt and (not top or tt > top) then top = tt end
				if tb and (not bottom or tb < bottom) then bottom = tb end
			end
			local tabTop, tabBottom = preview:GetTop(), preview:GetBottom()
			if not (top and bottom and tabTop and tabBottom) then return end
			-- the arrow buttons hang above/below the slider itself, so inset it by their height
			slider:ClearAllPoints()
			slider:SetPoint("TOPRIGHT", preview, "TOPRIGHT", -6, (top - upBtn:GetHeight()) - tabTop)
			slider:SetPoint("BOTTOMRIGHT", preview, "BOTTOMRIGHT", -6, (bottom + downBtn:GetHeight()) - tabBottom)
		end
		AlignSlider()
		-- the tile layout changes with the item type, so re-align whenever it is rebuilt or shown
		hooksecurefunc(list, "SetupModel", AlignSlider)
		hooksecurefunc(list, "Update", AlignSlider)
		preview:HookScript("OnShow", AlignSlider)
	end

	-- 9) Appearances tab: the two list panels
	local appearances = main.tabs.appearances
	for _, panel in ipairs({ appearances.saved, appearances.received }) do
		if panel then
			panel:SetTemplate("Default")
			ColorBorderPersistent(panel)
		end
	end

	-- 10) Settings tab: line everything up in two columns - labels on the left; the dropdowns and the
	--     colour swatch share one column on the right (so their left edges match)
	local settings = main.tabs.settings
	local swatch = settings:GetName() and _G[settings:GetName() .. "BorderDressingRoomBackgroundColorPicker"]
	if swatch then
		swatch:SetTemplate("Default")
		ColorBorderPersistent(swatch)
	end

	local function FindLabel(frame, text)
		if not frame then return nil end
		for _, region in ipairs({ frame:GetRegions() }) do
			if region:GetObjectType() == "FontString" and region:GetText() == text then
				return region
			end
		end
	end
	local label1 = FindLabel(settings.previewSetupMenu, "Used models:")
	local label2 = FindLabel(swatch, "Character background:")
	local colOffset -- distance from the labels' left edge to the shared column
	if label1 and label2 then
		colOffset = math.max(label1:GetStringWidth(), label2:GetStringWidth()) + 12
	end

	SkinDropDown(settings.previewSetupMenu, {
		extendRight = true,
		anchorLabel = colOffset and label1 or nil,
		anchorX = colOffset and (colOffset - 4) or nil, -- the box sits 4px inside the dropdown frame
	})
	SkinDropDown(settings.backgroundMenu, {
		extendRight = true,
		anchorLabel = colOffset and label2 or nil,
		anchorX = colOffset and (colOffset - 4) or nil,
	})

	-- "Reset Color" stays under the label; the swatch moves into the shared column on the same row
	local resetButton = swatch and swatch:GetName() and _G[swatch:GetName() .. "ResetButton"]
	if swatch and resetButton and colOffset then
		swatch:ClearAllPoints()
		swatch:SetSize(22, 22)
		swatch:SetPoint("LEFT", resetButton, "LEFT", colOffset, 0)
	end

	-- 11) Everything else: walk the window and skin text buttons, checkboxes and scroll frames
	local function Walk(frame, depth)
		if depth > 6 then return end
		for _, child in ipairs({ frame:GetChildren() }) do
			local otype = child:GetObjectType()
			local name = child:GetName()
			if otype == "CheckButton" then
				SkinCheck(child)
			elseif otype == "Button" then
				-- UIPanelButtonTemplate2 buttons have named Left/Middle/Right parts and a label
				local text = child:GetText()
				if name and _G[name .. "Left"] and text and text ~= "" then
					SkinTextButton(child)
				end
			elseif otype == "ScrollFrame" then
				if name then SkinScrollBar(_G[name .. "ScrollBar"]) end
			end
			Walk(child, depth + 1)
		end
	end
	Walk(main, 1)

	-- 12) The "DressMe" button on the character window
	local charButton = _G["CharacterModelFrameDressMeDressMeButton"]
	if charButton then SkinTextButton(charButton) end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	Skin()
end)
if IsLoggedIn() then Skin() end