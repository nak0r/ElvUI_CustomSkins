local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

-- ---------------------------------------------------------------------------
-- Options
-- ---------------------------------------------------------------------------
-- false = skin the price history graph above the scan tooltip (black background, border colour from BORDER_MODE)
-- true  = hide that graph completely (the box around it, the plot, the grid lines and the labels)
local HIDE_PRICE_GRAPH = true

-- Border colour (buttons, windows, text boxes, check boxes, tabs, dropdown, history rows, tooltip):
--   "custom" = one solid colour that you choose (BORDER_R/G/B below)
--   "class"  = your class colour
--   "elvui"  = leave the borders to ElvUI / ElvUI_AddOnSkins (their default colours)
local BORDER_MODE = "elvui"
local BORDER_R, BORDER_G, BORDER_B = 0.45, 0.45, 0.45  -- the "custom" colour (gray)

-- Colour of the tick when a check box is checked: it fills the box (r, g, b), and the greyed-out version for disabled boxes
local CHECKBOX_FILL = { 1, 0.82, 0 }
local CHECKBOX_FILL_DISABLED = { 0.5, 0.5, 0.5 }

-- The skin follows the Market Watcher checkbox in ElvUI > AddOn Skins > Skins (AddOnSkins' on/off switch).
-- If the checkbox does not exist (the addon name is not in AddOnSkins' list) the skin is on.
local function IsSkinEnabled()
	local options = E.private and E.private.addOnSkins
	if not options then return true end
	for key, value in pairs(options) do
		if type(key) == "string" and key:lower() == "marketwatcher" then
			return value ~= false
		end
	end
	return true
end

-- ---------------------------------------------------------------------------
-- Border colour helpers
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

-- ElvUI buttons reset their border colour on mouse leave, so re-apply it
local function ColorBorderPersistent(frame)
	if MODE == "elvui" then return end
	if not frame or not frame.SetBackdropBorderColor then return end
	ColorBorder(frame)
	if not frame.mwBorderHooked then
		frame.mwBorderHooked = true
		frame:HookScript("OnLeave", ColorBorder)
		frame:HookScript("OnShow", ColorBorder)
	end
end

-- ElvUI edit box skin + our border colour on the box ElvUI draws around it
local function SkinEditBox(eb)
	S:HandleEditBox(eb)
	ColorBorder(eb.backdrop)
end

-- defined further down; declared here so SkinCheckBoxCustom can use it
local StyleCheckBoxBorder

-- Helper function to properly skin checkboxes and ensure checkmarks display
local function SkinCheckBoxCustom(chk)
	if not chk or chk.isElvUISkinned then return end

	S:HandleCheckBox(chk)

	local checkedTexture = chk:GetCheckedTexture()
	if checkedTexture then
		checkedTexture:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
		checkedTexture:SetVertexColor(1, 0.82, 0, 1)
		checkedTexture:SetInside()
	end

	chk:HookScript("OnClick", function(self)
		local check = self:GetCheckedTexture()
		if check then
			if self:GetChecked() then
				check:Show()
			else
				check:Hide()
			end
		end
	end)

	chk.isElvUISkinned = true

	StyleCheckBoxBorder(chk)
end

-- Border + solid fill for a skinned check box. The ElvUI border frame is a child of the check box and can paint over
-- the tick, so its fill is made see-through and the fill/border are drawn as textures on the check box itself.
function StyleCheckBoxBorder(chk)
	if not chk or chk.mwBoxStyled then return end
	chk.mwBoxStyled = true

	local bd = chk.backdrop
	local c = (E.media and E.media.backdropcolor) or { 0.1, 0.1, 0.1 }
	if bd then
		if bd.SetBackdropColor then bd:SetBackdropColor(c[1], c[2], c[3], 0) end
		if bd.SetBackdropBorderColor then bd:SetBackdropBorderColor(0, 0, 0, 0) end
	end

	-- the square we draw around: the ElvUI box if there is one, otherwise the check box inset a little
	local anchor, inset = chk, 4
	if bd then anchor, inset = bd, 0 end

	local fill = chk:CreateTexture(nil, "BACKGROUND")
	fill:SetPoint("TOPLEFT", anchor, "TOPLEFT", inset, -inset)
	fill:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -inset, inset)
	fill:SetTexture(c[1], c[2], c[3], 1)

	local r, g, b = GetBorderColor()
	local edges = {}
	for i = 1, 4 do
		edges[i] = chk:CreateTexture(nil, "OVERLAY")
		edges[i]:SetTexture(r, g, b, 1)
	end
	edges[1]:SetPoint("TOPLEFT", anchor, "TOPLEFT", inset, -inset)
	edges[1]:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", -inset, -inset)
	edges[1]:SetHeight(1)
	edges[2]:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", inset, inset)
	edges[2]:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -inset, inset)
	edges[2]:SetHeight(1)
	edges[3]:SetPoint("TOPLEFT", anchor, "TOPLEFT", inset, -inset)
	edges[3]:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", inset, inset)
	edges[3]:SetWidth(1)
	edges[4]:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", -inset, -inset)
	edges[4]:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -inset, inset)
	edges[4]:SetWidth(1)

	-- the "tick" is a solid square that fills the bordered box (2px in from the border)
	local function FillTexture(tex, color)
		if not tex then return end
		tex:SetTexture(color[1], color[2], color[3], 1)
		tex:SetVertexColor(1, 1, 1, 1)
		tex:SetTexCoord(0, 1, 0, 1)
		tex:ClearAllPoints()
		tex:SetPoint("TOPLEFT", anchor, "TOPLEFT", inset + 2, -(inset + 2))
		tex:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -(inset + 2), inset + 2)
	end
	FillTexture(chk:GetCheckedTexture(), CHECKBOX_FILL)
	FillTexture(chk.GetDisabledCheckedTexture and chk:GetDisabledCheckedTexture(), CHECKBOX_FILL_DISABLED)
end

-- The Filters window's check boxes are created by the addon the first time the window is used
local function SkinFilterCheckBoxes()
	local i = 1
	local chk = _G["MarketWatcherFilter1CheckButton"]
	while chk do
		SkinCheckBoxCustom(chk)
		StyleCheckBoxBorder(chk)
		i = i + 1
		chk = _G["MarketWatcherFilter" .. i .. "CheckButton"]
	end
end

-- Helper function to apply ElvUI button skin with a distinct border template and centered text
local function SkinButtonWithBorder(btn)
	if not btn or btn.isElvUISkinned then return end
	
	S:HandleButton(btn)
	if btn.SetTemplate then
		btn:SetTemplate("Default")
	end
	ColorBorderPersistent(btn)
	
	for _, region in ipairs({ btn:GetRegions() }) do
		if region and region:IsObjectType("FontString") then
			region:SetJustifyH("CENTER")
			region:SetJustifyV("MIDDLE")
		end
	end
	
	btn.isElvUISkinned = true
end

-- Dedicated function to skin the Add Item pop-up frame whenever it appears
local function SkinAddItemWindow()
	local addFrame = _G["MarketWatcherHistoryAddItemFrame"]
	if addFrame and not addFrame.isElvUISkinned then
		addFrame:StripTextures()
		addFrame:SetTemplate("Default") -- solid background
		local solid = (E.media and E.media.backdropcolor) or { 0.1, 0.1, 0.1 }
		addFrame:SetBackdropColor(solid[1], solid[2], solid[3], 1)
		ColorBorder(addFrame)
		
		for _, child in ipairs({ addFrame:GetChildren() }) do
			if child and child.IsObjectType then
				if child:IsObjectType("EditBox") and not child.isElvUISkinned then
					SkinEditBox(child)
					child.isElvUISkinned = true
				elseif child:IsObjectType("Button") and not child.isElvUISkinned then
					SkinButtonWithBorder(child)
				elseif child:IsObjectType("Frame") and not child.isElvUISkinned then
					-- the "Name" and "ID" panels inside the window: tooltip-style border, see-through fill
					local bd = child.GetBackdrop and child:GetBackdrop()
					if bd and bd.edgeFile and bd.edgeFile:find("UI%-Tooltip%-Border") then
						child:SetTemplate("Default")
						child:SetBackdropColor(solid[1], solid[2], solid[3], 1)
						ColorBorder(child)
						child.isElvUISkinned = true
					end
				end
			end
		end
		
		addFrame.isElvUISkinned = true
	end

	local addElements = {
		"MarketWatcherHistoryAddItemFrameNameEditBox",
		"MarketWatcherHistoryAddItemFrameIdEditBox",
		"MarketWatcherHistoryAddItemFrameItemIDEditBox",
		"MarketWatcherHistoryAddItemFrameNameGetItemInfoButton",
		"MarketWatcherHistoryAddItemFrameNameAddButton",
		"MarketWatcherHistoryAddItemFrameIdGetItemInfoButton",
		"MarketWatcherHistoryAddItemFrameIdAddButton",
		"MarketWatcherHistoryAddItemFrameGetInfoButton",
		"MarketWatcherHistoryAddItemFrameAddButton",
		"MarketWatcherHistoryAddItemFrameCloseButton"
	}
	for _, name in ipairs(addElements) do
		local el = _G[name]
		if el and not el.isElvUISkinned then
			if el:IsObjectType("EditBox") then
				SkinEditBox(el)
			elseif el:IsObjectType("Button") then
				SkinButtonWithBorder(el)
			end
			el.isElvUISkinned = true
		end
	end
end

-- Scan page, sell options: make the "Bid" / "Buyout" labels and the gold / silver / copper boxes easier to read
-- Font sizes of the "Bid"/"Buyout" labels and of the gold/silver/copper boxes in the sell options panel.
-- The gaps between the rows are widened to fit the labels (see SpaceSellOptions).
local SELL_LABEL_SIZE, SELL_BOX_SIZE = 18, 18

local function EnlargeSellOptionsText(root)
	local LABEL_SIZE, BOX_SIZE = SELL_LABEL_SIZE, SELL_BOX_SIZE
	local function SetSize(obj, size)
		local font, cur, flags = obj:GetFont()
		if font and (not cur or math.abs(cur - size) > 0.5) then obj:SetFont(font, size, flags) end
	end
	local function Visit(frame)
		for _, region in ipairs({ frame:GetRegions() }) do
			if region:GetObjectType() == "FontString" then
				local t = region:GetText()
				if t then
					t = t:lower()
					if t:find("^bid") or t:find("^buyout") then SetSize(region, LABEL_SIZE) end
				end
			end
		end
		for _, child in ipairs({ frame:GetChildren() }) do
			if child:IsObjectType("EditBox") then SetSize(child, BOX_SIZE) end
			Visit(child)
		end
	end
	Visit(root)
end

-- Each "Bid" / "Buyout" label is drawn just above its row of boxes, inside the gap left by the row above. That gap was
-- sized for tiny labels, so the bigger label ran into the boxes above it. The rows hang off each other in a chain
-- (Radios > Sell One Bid > Sell One Buyout > Sell One button > Sell Stack Bid > Sell Stack Buyout > ...), so
-- pushing a row down by a few pixels moves everything below it by the same amount. Done once.
local function SpaceSellOptions(sellFrame)
	if sellFrame.mwSpaced then return end

	local prefix = "MarketWatcherScanFrameAuctionsSellOptions"
	local gapBuyout = math.max(0, SELL_LABEL_SIZE + 5 - 15) -- Bid row -> Buyout row (gap was 15)
	local gapOther = math.max(0, SELL_LABEL_SIZE - 14)      -- under the radio buttons / under the Sell One button
	local tweaks = {
		{ "SellOneBidMoney", gapOther },
		{ "SellOneBuyoutMoney", gapBuyout },
		{ "SellStackBidMoney", gapOther },
		{ "SellStackBuyoutMoney", gapBuyout },
	}
	for _, t in ipairs(tweaks) do
		if not _G[prefix .. t[1]] then return end -- not created yet: try again later
	end
	for _, t in ipairs(tweaks) do
		local f = _G[prefix .. t[1]]
		local point, rel, relPoint, x, y = f:GetPoint(1)
		if point then
			f:ClearAllPoints()
			f:SetPoint(point, rel, relPoint, x or 0, (y or 0) - t[2])
		end
	end
	sellFrame.mwSpaced = true
end

local function UpdateSellOptions(frame)
	EnlargeSellOptionsText(frame)
	local ok, err = pcall(SpaceSellOptions, frame)
	if not ok then
		frame.mwSpaced = true -- do not try again
		DEFAULT_CHAT_FRAME:AddMessage("|cffffd100MarketWatcher skin:|r could not space the sell options: " .. tostring(err))
	end
end

-- /mwsell : with the Scan page's sell panel (Sell One / Sell Stack) open, print how its pieces are laid out
SLASH_MWSELL1 = "/mwsell"
SlashCmdList["MWSELL"] = function()
	local say = function(m) DEFAULT_CHAT_FRAME:AddMessage("|cffffd100MWsell|r " .. m) end
	local root = _G["MarketWatcherScanFrameAuctionsSellOptions"]
	if not root then say("sell options frame not found") return end
	local function Name(o) return o and (o:GetName() or ("<" .. o:GetObjectType() .. ">")) or "nil" end
	local function Describe(o, indent)
		local pts = {}
		for i = 1, (o:GetNumPoints() or 0) do
			local p, rel, rp, x, y = o:GetPoint(i)
			pts[#pts + 1] = string.format("%s>%s.%s(%.0f,%.0f)", p, Name(rel), tostring(rp), x or 0, y or 0)
		end
		local extra = ""
		if o:GetObjectType() == "FontString" then
			local _, size = o:GetFont()
			extra = string.format(" text=[%s] size=%s", tostring(o:GetText()), tostring(size and math.floor(size + 0.5)))
		elseif o.GetFont and o:IsObjectType("EditBox") then
			local _, size = o:GetFont()
			extra = " fontsize=" .. tostring(size and math.floor(size + 0.5))
		end
		say(string.format("%s%s [%s] %.0fx%.0f top=%.0f %s%s", indent, Name(o), o:GetObjectType(),
			o:GetWidth() or 0, o:GetHeight() or 0, o:GetTop() or -1, table.concat(pts, " "), extra))
	end
	local function Walk(frame, indent)
		Describe(frame, indent)
		for _, r in ipairs({ frame:GetRegions() }) do
			if r:GetObjectType() == "FontString" then Describe(r, indent .. "  ") end
		end
		for _, c in ipairs({ frame:GetChildren() }) do Walk(c, indent .. "  ") end
	end
	Walk(root, "")
end

-- Dedicated function to skin the Scan auctions sell/rescan options panel
local function SkinSellOptionsWindow()
	local sellFrame = _G["MarketWatcherScanFrameAuctionsSellOptions"]
	if sellFrame then
		UpdateSellOptions(sellFrame)
		-- the bid / buyout boxes inside are created by the addon after the skin first runs, so keep checking
		if not sellFrame.mwBigTextHooked then
			sellFrame.mwBigTextHooked = true
			local elapsed = 0
			sellFrame:HookScript("OnShow", function(self) UpdateSellOptions(self) end)
			sellFrame:HookScript("OnUpdate", function(self, dt)
				elapsed = elapsed + dt
				if elapsed > 0.5 then
					elapsed = 0
					UpdateSellOptions(self)
				end
			end)
		end
		if not sellFrame.isElvUISkinned then
			sellFrame:StripTextures()
			sellFrame:SetTemplate("Transparent")
			ColorBorder(sellFrame)
			sellFrame.isElvUISkinned = true
			
			sellFrame:HookScript("OnShow", function(self)
				for _, region in ipairs({ self:GetRegions() }) do
					if region and region:IsObjectType("FontString") then
						local text = region:GetText() or ""
						if text:find("Tradeskill") or text:find("Selected") then
							region:Hide()
						end
					end
				end
			end)
		end
		
		local minHeight = 350 + (sellFrame.mwExtraHeight or 0)
		if sellFrame:GetHeight() < minHeight then
			sellFrame:SetHeight(minHeight)
		end
		
		for _, region in ipairs({ sellFrame:GetRegions() }) do
			if region and region:IsObjectType("FontString") then
				local text = region:GetText() or ""
				if text:find("Tradeskill") or text:find("Selected") then
					region:Hide()
					region:SetText("")
				elseif text == "Bid" or text == "Buvout" or text == "Buyout" then
					local font, size, flags = region:GetFont()
					if size then
						region:SetFont(font, 13, flags)
					end
				end
			end
		end
	end

	local sellButtons = {
		"MarketWatcherScanFrameAuctionsSellOptionsSellOneButton",
		"MarketWatcherScanFrameAuctionsSellOptionsSellStackButton",
		"MarketWatcherScanFrameAuctionsSellOptionsCreateButton",
		"MarketWatcherScanFrameAuctionsSellOptionsCancelAuctionsButton",
		"MarketWatcherScanFrameAuctionsSellOptionsRescanItemButton"
	}
	for _, btnName in ipairs(sellButtons) do
		local btn = _G[btnName]
		if btn then
			if not btn.isElvUISkinned then
				SkinButtonWithBorder(btn)
				btn.isElvUISkinned = true
			end
			for _, region in ipairs({ btn:GetRegions() }) do
				if region and region:IsObjectType("FontString") then
					region:SetJustifyH("CENTER")
					region:SetJustifyV("MIDDLE")
				end
			end
		end
	end
end

-- Skin the Edit Filters window: Blizzard dialog border + header plate -> ElvUI frame, ElvUI close button.
-- (The scroll bar is deliberately left alone.)
local function SkinFiltersWindow()
	local frame = _G["MarketWatcherFiltersFrame"]
	if not frame then return end

	if not frame.isElvUISkinned then
		frame:StripTextures()           -- slot background art and the dialog header plate
		frame:SetTemplate("Default") -- replaces the Blizzard dialog border, solid background
		local bg = (E.media and E.media.backdropcolor) or { 0.1, 0.1, 0.1 }
		frame:SetBackdropColor(bg[1], bg[2], bg[3], 1)
		ColorBorder(frame)

		-- the dark textured panel behind the list of filters
		local child = _G["MarketWatcherFiltersFrameScrollBarChildFrame"]
		if child then child:StripTextures() end

		-- the "Filters" title used to sit on the header plate; drop it just inside the new border
		for _, region in ipairs({ frame:GetRegions() }) do
			if region:IsObjectType("FontString") then
				local point = region:GetPoint(1)
				if point == "TOP" then
					region:ClearAllPoints()
					region:SetPoint("TOP", frame, "TOP", 0, -8)
				end
			end
		end

		frame.isElvUISkinned = true
	end

	SkinFilterCheckBoxes()

	local closeBtn = _G["MarketWatcherFiltersFrameCloseButton"]
	if closeBtn and not closeBtn.isElvUISkinned then
		SkinButtonWithBorder(closeBtn)
	end
end

-- Skin the Configure window (sliders, three check boxes, Memory Audit / Okay / Cancel).
-- The check boxes are created by the addon the first time the window is shown, so this also runs on every show.
local function SkinConfigWindow()
	local frame = _G["MarketWatcherConfigFrame"]
	if not frame then return end

	if not frame.isElvUISkinned then
		frame:StripTextures()
		frame:SetTemplate("Default")
		local bg = (E.media and E.media.backdropcolor) or { 0.1, 0.1, 0.1 }
		frame:SetBackdropColor(bg[1], bg[2], bg[3], 1)
		ColorBorder(frame)

		local title = _G["MarketWatcherConfigFrameTitle"]
		if title then
			title:ClearAllPoints()
			title:SetPoint("TOP", frame, "TOP", 0, -8)
		end

		frame.isElvUISkinned = true
	end

	for _, name in ipairs({
		"MarketWatcherConfigFrameQueryDelaySlider",
		"MarketWatcherConfigFrameDefaultUndercutSlider",
		"MarketWatcherConfigFrameBidPriceMarkdownSlider",
	}) do
		local slider = _G[name]
		if slider and not slider.isElvUISkinned then
			if S.HandleSliderFrame then S:HandleSliderFrame(slider) end
			slider.isElvUISkinned = true
		end
	end

	for i = 1, 3 do
		local chk = _G["MarketWatcherConfigFrameCheckButton" .. i]
		if chk then
			SkinCheckBoxCustom(chk)
			StyleCheckBoxBorder(chk)
		end
	end

	for _, name in ipairs({
		"MarketWatcherConfigFrameAuditButton",
		"MarketWatcherConfigFrameOkayButton",
		"MarketWatcherConfigFrameCancelButton",
	}) do
		local btn = _G[name]
		if btn and not btn.isElvUISkinned then SkinButtonWithBorder(btn) end
	end
end

-- History page: the time period dropdown and the Low / Average / High series check boxes next to the graph.
-- The check boxes are created by the addon the first time a graph is built, so this runs again after that.
local function SkinHistoryGraphOptions()
	local dd = _G["MarketWatcherHistoryFrameGraphPeriodDropDown"]
	if dd and not dd.mwDropSkinned then
		dd.mwDropSkinned = true
		if S.HandleDropDownBox then S:HandleDropDownBox(dd, 140) end
	end

	-- Solid background + text kept inside the box. Same trick as the text boxes: the ElvUI box is a child frame that can
	-- paint over (or hide behind) the text, so make its fill see-through and draw a solid fill on the dropdown itself.
	if dd and dd.backdrop and not dd.mwFill then
		local bd = dd.backdrop
		ColorBorder(bd)
		local c = (E.media and E.media.backdropcolor) or { 0.1, 0.1, 0.1 }
		if bd.SetBackdropColor then bd:SetBackdropColor(c[1], c[2], c[3], 0) end

		dd.mwFill = dd:CreateTexture(nil, "BACKGROUND")
		dd.mwFill:SetPoint("TOPLEFT", bd, "TOPLEFT", 1, -1)
		dd.mwFill:SetPoint("BOTTOMRIGHT", bd, "BOTTOMRIGHT", -1, 1)
		dd.mwFill:SetTexture(c[1], c[2], c[3], 1)

		-- the selected value ("Entire History") sits inside the box, left of the arrow button
		local text = _G[dd:GetName() .. "Text"]
		if text then
			text:ClearAllPoints()
			text:SetPoint("LEFT", bd, "LEFT", 6, 0)
			text:SetPoint("RIGHT", bd, "RIGHT", -24, 0)
			text:SetJustifyH("LEFT")
			text:SetWidth(0) -- let the two anchors decide the width (the dropdown template sets a narrow fixed one)
		end
	end

	-- The ElvUI dropdown draws its box 20px in from the frame's left edge, which left it shifted left of the check
	-- boxes. Anchor it above the "Low" label instead (box left edge lines up with the label, as it originally did).
	-- DROPDOWN_X / DROPDOWN_Y nudge it: increase X to move it right, increase Y to move it up.
	local DROPDOWN_X, DROPDOWN_Y = -20, 39
	local label = _G["MarketWatcherHistoryFrameGraphSeriesText1"]
	if dd and label and not dd.mwAnchored then
		dd.mwAnchored = true
		dd:ClearAllPoints()
		dd:SetPoint("TOPLEFT", label, "TOPLEFT", DROPDOWN_X, DROPDOWN_Y)
	end

	-- The drop-down list (Last Month / Last 2 Weeks / ...) gets a solid background while this dropdown is open
	if dd and DropDownList1 and not DropDownList1.mwSolidHooked then
		DropDownList1.mwSolidHooked = true
		local panels = { "DropDownList1Backdrop", "DropDownList1MenuBackdrop" }
		DropDownList1:HookScript("OnShow", function()
			if UIDROPDOWNMENU_OPEN_MENU ~= _G["MarketWatcherHistoryFrameGraphPeriodDropDown"] then return end
			local c = (E.media and E.media.backdropcolor) or { 0.1, 0.1, 0.1 }
			for _, n in ipairs(panels) do
				local p = _G[n]
				if p and p.SetBackdropColor then
					if not p.mwOldColor then
						local r, g, b, a = p:GetBackdropColor()
						p.mwOldColor = { r or c[1], g or c[2], b or c[3], a or 1 }
					end
					p:SetBackdropColor(c[1], c[2], c[3], 1)
				end
			end
		end)
		DropDownList1:HookScript("OnHide", function()
			for _, n in ipairs(panels) do
				local p = _G[n]
				if p and p.mwOldColor then
					p:SetBackdropColor(p.mwOldColor[1], p.mwOldColor[2], p.mwOldColor[3], p.mwOldColor[4])
					p.mwOldColor = nil
				end
			end
		end)
	end

	for series = 1, 6 do
		for method = 1, 8 do
			local chk = _G["MarketWatcherHistoryFrameGraphSeries" .. series .. "MethodCheckBox" .. method]
			if chk then SkinCheckBoxCustom(chk) end
		end
	end
end

-- The "Unhide" button that appears at the top of the scan page when items have been hidden: ElvUI button, but red
local function SkinUnhideButton()
	local btn = _G["MarketWatcherScanFrameUnHideButton"]
	if not btn then return end
	SkinButtonWithBorder(btn)
	if btn.mwRed then return end
	btn.mwRed = true

	local function Paint(self)
		self:SetBackdropColor(0.55, 0.08, 0.08, 1)
		self:SetBackdropBorderColor(0.85, 0.15, 0.15, 1)
		local fs = self:GetFontString()
		if fs then fs:SetTextColor(1, 1, 1) end
	end
	Paint(btn)
	btn:HookScript("OnShow", Paint)
	btn:HookScript("OnLeave", Paint) -- ElvUI puts the normal border colour back when the mouse leaves
end

-- Dedicated function to skin the scan status/abort dialog when active
local function SkinScanStatusWindow()
	local abortBtn = _G["MarketWatcherScanFrameStatusAbortButton"]
	if abortBtn and not abortBtn.isElvUISkinned then
		SkinButtonWithBorder(abortBtn)
		abortBtn.isElvUISkinned = true
	end
end

-- Safely skin the dropdown button without shifting its parent container box
local function SkinDropDownCustom()
	local historyFrame = _G["MarketWatcherHistoryFrame"]
	if historyFrame then
		local function CheckChildren(parent)
			if not parent then return end
			for _, child in ipairs({ parent:GetChildren() }) do
				if child and child.IsObjectType then
					local name = child:GetName() or ''
					if name:find("DropDown") or (child.Button and child.Text) then
						if not child.isElvUISkinned then
							if child.Button and not child.Button.isElvUISkinned then
								S:HandleNextPrevButton(child.Button)
								child.Button.isElvUISkinned = true
							end
							child.isElvUISkinned = true
						end
					end
				end
				CheckChildren(child)
			end
		end
		CheckChildren(historyFrame)
	end
end

-- Strip the ElvUI boxes around a scrollbar: the track, the arrow buttons and any
-- other child frame. The frame anchored to the thumb texture is kept, so the thumb
-- still shows. Accepts a frame or a frame name.
local function LockHidden(f)
	f:Hide()
	f:SetAlpha(0)
	if not f.mwHidden then
		f.Show = E.noop -- stop anything from re-showing it
		f.mwHidden = true
	end
end

-- The border/track art lives on the scroll frame that owns the scrollbar (its own
-- textures), so clear those too.
local function StripScrollFrameTextures(sf)
	for _, r in ipairs({ sf:GetRegions() }) do
		if r:GetObjectType() == "Texture" then
			r:Hide()
			r:SetAlpha(0)
			if not r.mwHidden then
				r.Show = E.noop
				r.mwHidden = true
			end
		end
	end
end

local function RemoveScrollBarBackdrop(sb)
	if type(sb) == "string" then sb = _G[sb] end
	if not sb then return end

	local thumb = sb.GetThumbTexture and sb:GetThumbTexture()

	if sb.trackbg then LockHidden(sb.trackbg) end
	if sb.backdrop then LockHidden(sb.backdrop) end

	for _, child in ipairs({ sb:GetChildren() }) do
		local keep = (child == sb.thumbbg)
		if thumb and not keep then
			for i = 1, child:GetNumPoints() do
				local _, rel = child:GetPoint(i)
				if rel == thumb then keep = true end
			end
		end
		if not keep then LockHidden(child) end
	end

	local parent = sb:GetParent()
	if parent and parent.IsObjectType and parent:IsObjectType("ScrollFrame") then
		StripScrollFrameTextures(parent)
	end
end

-- Find every Slider under a frame (named or not) and strip its track box
local function StripAllScrollBars(parent)
	if not parent then return end
	for _, child in ipairs({ parent:GetChildren() }) do
		if child.IsObjectType and child:IsObjectType("Slider") then
			RemoveScrollBarBackdrop(child)
		end
		StripAllScrollBars(child)
	end
end

-- Skin Market Watcher's own tooltip (the one that pops up beside a scan result).
-- Its frame name isn't known, so find the visible tooltip owned by / anchored to the hovered button.
local mwTooltip
local function SkinTooltipNear(btn)
	if mwTooltip then return true end

	local f = EnumerateFrames()
	while f do
		if f ~= GameTooltip and f ~= ItemRefTooltip and f.IsVisible and f:IsVisible() then
			local isTip = (f:GetObjectType() == "GameTooltip")
			if not isTip and f.GetBackdrop then
				local bd = f:GetBackdrop()
				isTip = bd and bd.edgeFile and bd.edgeFile:find("UI%-Tooltip%-Border") and true or false
			end

			if isTip then
				local owner = f.GetOwner and f:GetOwner()
				local _, rel = f:GetPoint(1)
				if owner == btn or rel == btn then
					mwTooltip = f
					if f.SetTemplate then
						local function Apply(self)
							self:SetTemplate("Transparent")
							self:SetBackdropColor(0, 0, 0, 1) -- solid black background
							ColorBorder(self)
						end
						Apply(f)
						-- Blizzard resets the tooltip backdrop when it hides/shows, so re-apply
						f:HookScript("OnShow", Apply)
					end
					return true
				end
			end
		end
		f = EnumerateFrames(f)
	end
	return false
end

-- Keep the normal item tooltip (GameTooltip) in its original spot, but shift it left
-- just far enough that it doesn't overlap Market Watcher's tooltip.
local function PlaceItemTooltip(btn)
	if not mwTooltip or not mwTooltip:IsShown() or not GameTooltip:IsShown() then return end
	if GameTooltip:GetOwner() ~= btn then return end

	local gs, ms = GameTooltip:GetEffectiveScale(), mwTooltip:GetEffectiveScale()
	local gL, gR, gT, gB = GameTooltip:GetLeft(), GameTooltip:GetRight(), GameTooltip:GetTop(), GameTooltip:GetBottom()
	local mL, mR, mT, mB = mwTooltip:GetLeft(), mwTooltip:GetRight(), mwTooltip:GetTop(), mwTooltip:GetBottom()
	if not (gL and gR and gT and gB and mL and mR and mT and mB) then return end

	-- compare in screen pixels
	gL, gR, gT, gB = gL * gs, gR * gs, gT * gs, gB * gs
	mL, mR, mT, mB = mL * ms, mR * ms, mT * ms, mB * ms

	local gap = 4 * ms
	local overlapsX = gR > (mL - gap) and gL < mR
	local overlapsY = gB < mT and gT > mB
	if not (overlapsX and overlapsY) then return end

	local dx = (gR - (mL - gap)) / gs -- how far to move left, in GameTooltip units
	local point, rel, relPoint, x, y = GameTooltip:GetPoint(1)
	if not point then return end
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint(point, rel, relPoint, (x or 0) - dx, y or 0)
end

-- Skin the price history graph that sits above the tooltip on the scan page. It has Blizzard's grey
-- rounded tooltip border; give it the same look as the Market Watcher tooltip (solid black, white border).
-- Its frame name isn't known either, so find visible frames that use the tooltip border graphic and are
-- tied to the hovered button or to one of the tooltips (anchored to it, owned by it, or inside it).
local mwGraphSkinned = setmetatable({}, { __mode = "k" })

local function SkinGraphBackdrop(f)
	if mwGraphSkinned[f] then return end
	mwGraphSkinned[f] = true

	if HIDE_PRICE_GRAPH then
		-- turn the graph off: hide it now and every time the addon shows it again
		f:Hide()
		f:HookScript("OnShow", function(self) self:Hide() end)
		return
	end

	if not f.SetTemplate then return end
	local function Apply(self)
		self:SetTemplate("Transparent")
		self:SetBackdropColor(0, 0, 0, 1)     -- solid black background
		ColorBorder(self)
	end
	Apply(f)
	f:HookScript("OnShow", Apply) -- Blizzard resets tooltip backdrops when they hide/show
end

-- Hides a frame now and again every time the addon shows it
local function HideForGood(f)
	if mwGraphSkinned[f] then return end
	mwGraphSkinned[f] = true
	f:Hide()
	f:HookScript("OnShow", function(self) self:Hide() end)
end

-- The graph itself (grid, data line, axis labels) is a separate frame from the bordered box around it.
-- Graph libraries such as LibGraph give their frames methods like AddDataSeries / RefreshGraph; failing
-- that, a frame with "graph" in its name counts.
local function LooksLikeGraph(f)
	if type(f.AddDataSeries) == "function" or type(f.RefreshGraph) == "function"
		or type(f.SetGridSpacing) == "function" then
		return true
	end
	local name = f.GetName and f:GetName()
	return (name and name:lower():find("graph") and true) or false
end

local function InsideMarketWatcher(f)
	local p = f
	for _ = 1, 8 do
		if not p then break end
		local name = p.GetName and p:GetName()
		if name and name:find("^MarketWatcher") then return true end
		p = p:GetParent()
	end
	return false
end

local function IsTiedToTooltip(f, btn)
	local p = f
	for _ = 1, 6 do
		if not p then break end
		if p == btn or (mwTooltip and p == mwTooltip) or p == GameTooltip then return true end
		local owner = p.GetOwner and p:GetOwner()
		if owner == btn then return true end
		local _, rel = p:GetPoint(1)
		if rel == btn or rel == GameTooltip or (mwTooltip and rel == mwTooltip) then return true end
		p = p:GetParent()
	end
	return false
end

local function SkinGraphFrames(btn)
	local f = EnumerateFrames()
	while f do
		if f ~= GameTooltip and f ~= ItemRefTooltip and f ~= mwTooltip
			and f.IsVisible and f:IsVisible() and not mwGraphSkinned[f] then
			local bd = f.GetBackdrop and f:GetBackdrop()
			if bd and bd.edgeFile and bd.edgeFile:find("UI%-Tooltip%-Border") and IsTiedToTooltip(f, btn) then
				SkinGraphBackdrop(f)
			elseif HIDE_PRICE_GRAPH and LooksLikeGraph(f) and (IsTiedToTooltip(f, btn) or InsideMarketWatcher(f)) then
				HideForGood(f)
			end
		end
		f = EnumerateFrames(f)
	end
end

-- Border-only hover highlight for the scan results (same colour ElvUI buttons use on hover)
local function AddHoverBorder(btn)
	if btn.mwHoverBorder then return end

	local border = CreateFrame("Frame", nil, btn)
	border:SetAllPoints(btn)
	border:SetFrameLevel(btn:GetFrameLevel() + 2)
	border:SetBackdrop({ edgeFile = E.media.blankTex, edgeSize = E.mult or 1 })
	local c = E.media.rgbvaluecolor or { 1, 0.82, 0 }
	border:SetBackdropBorderColor(c[1], c[2], c[3])
	border:Hide()
	btn.mwHoverBorder = border

	-- replace the addon's own highlight with the border
	btn:SetHighlightTexture("")

	btn:HookScript("OnEnter", function(self)
		self.mwHoverBorder:Show()
		if SkinTooltipNear(self) then
			PlaceItemTooltip(self)
		end
		SkinGraphFrames(self)
		-- check again shortly in case the tooltips finished setting up after this hook ran
		C_Timer.After(0.05, function()
			SkinTooltipNear(self)
			SkinGraphFrames(self)
			PlaceItemTooltip(self)
		end)
		C_Timer.After(0.25, function() SkinGraphFrames(self) end)
		C_Timer.After(0.6, function() SkinGraphFrames(self) end)
	end)
	btn:HookScript("OnLeave", function(self)
		if not self.mwLocked then self.mwHoverBorder:Hide() end
	end)
	btn:HookScript("OnHide", function(self) self.mwHoverBorder:Hide() end)

	-- if the addon marks the selected result with LockHighlight, show the border for that too
	hooksecurefunc(btn, "LockHighlight", function(self)
		self.mwLocked = true
		self.mwHoverBorder:Show()
	end)
	hooksecurefunc(btn, "UnlockHighlight", function(self)
		self.mwLocked = false
		if not self:IsMouseOver() then self.mwHoverBorder:Hide() end
	end)
end

-- Fit a history list item's icon and text inside its skinned button
local function AlignListItem(btn)
	local name = btn:GetName()
	local h = btn:GetHeight()
	if not h or h < 10 then h = 32 end

	-- find the icon: by name first, otherwise the small square texture on the button
	local icon = (name and (_G[name .. "Icon"] or _G[name .. "ItemIcon"] or _G[name .. "IconTexture"])) or btn.icon or btn.Icon
	if not icon then
		for _, r in ipairs({ btn:GetRegions() }) do
			if r:GetObjectType() == "Texture" then
				local w, rh = r:GetWidth(), r:GetHeight()
				if w and w > 8 and w <= h + 8 and rh and math.abs(w - rh) < 1 then
					icon = r
					break
				end
			end
		end
	end

	if icon then
		icon:ClearAllPoints()
		icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
		icon:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 2, 2)
		icon:SetWidth(h - 4)
		icon:SetTexCoord(unpack(E.TexCoords))
	end

	for _, r in ipairs({ btn:GetRegions() }) do
		if r:GetObjectType() == "FontString" then
			r:ClearAllPoints()
			if icon then
				r:SetPoint("LEFT", icon, "RIGHT", 4, 0)
			else
				r:SetPoint("LEFT", btn, "LEFT", 6, 0)
			end
			r:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
			r:SetWordWrap(false)
		end
	end
end

local function SkinMarketWatcherElements(parent)
	if not parent then return end

	for _, child in ipairs({ parent:GetChildren() }) do
		if child and child.IsObjectType then
			local name = child:GetName() or ""

			if name:find("PrevPageButton") or name:find("NextPageButton") then
				if not child.isElvUISkinned then
					S:HandleNextPrevButton(child)
					child.isElvUISkinned = true
				end
			elseif name:find("MarketWatcherScanFrameStatsButton") and child:IsObjectType("Button") then
				AddHoverBorder(child)
			elseif child:IsObjectType("Button") and not child.isElvUISkinned then
				if not name:find("SellOptions") and not name:find("AuctionsButton") and not name:find("MarketWatcherList") and (name:find("ItemSelect") or name:find("ItemButton")) then
					child:StripTextures()
					local icon = _G[name.."Icon"] or _G[name.."ItemIcon"] or child.icon or child.Icon
					if icon then
						icon:SetTexCoord(unpack(E.TexCoords))
						icon:SetInside()
						child:SetTemplate("Default")
						ColorBorderPersistent(child)
					else
						SkinButtonWithBorder(child)
					end
					
					child:SetWidth(152)
					
					AlignListItem(child)
					
					child.isElvUISkinned = true
				end
			elseif child:IsObjectType("CheckButton") and not child.isElvUISkinned then
				SkinCheckBoxCustom(child)
			elseif child:IsObjectType("Slider") and not child.isElvUISkinned then
				S:HandleScrollBar(child)
				RemoveScrollBarBackdrop(child)
				child.isElvUISkinned = true
			elseif child:IsObjectType("EditBox") and not child.isElvUISkinned then
				SkinEditBox(child)
				child.isElvUISkinned = true
			end

			SkinMarketWatcherElements(child)
		end
	end
end

-- ---------------------------------------------------------------------------
-- History tab, list view: column sort headers, first/last page arrows and the result rows
-- ---------------------------------------------------------------------------

-- Border-only hover highlight for a row (same colour ElvUI buttons use on hover)
local function AddRowHoverBorder(btn)
	if btn.mwHoverBorder then return end
	local border = CreateFrame("Frame", nil, btn)
	border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
	border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 5) -- same band as the row background
	border:SetFrameLevel(btn:GetFrameLevel() + 2)
	border:SetBackdrop({ edgeFile = E.media.blankTex, edgeSize = E.mult or 1 })
	local c = E.media.rgbvaluecolor or { 1, 0.82, 0 }
	border:SetBackdropBorderColor(c[1], c[2], c[3])
	border:Hide()
	btn.mwHoverBorder = border

	btn:SetHighlightTexture("")
	btn:HookScript("OnEnter", function(self) self.mwHoverBorder:Show() end)
	btn:HookScript("OnLeave", function(self) self.mwHoverBorder:Hide() end)
	btn:HookScript("OnHide", function(self) self.mwHoverBorder:Hide() end)
end

-- Column headers (Item, #, Time Left, Seller, Current Bid). The Blizzard header art is hidden and replaced by an
-- ElvUI box with gold text. The little sort-direction arrow is a separate texture and is left alone.
local function SkinSortHeader(btn)
	if btn.mwSortSkinned then return end
	btn.mwSortSkinned = true

	local name = btn:GetName()
	if name then
		for _, part in ipairs({ "Left", "Middle", "Right" }) do
			local tex = _G[name .. part]
			if tex then tex:SetAlpha(0) end
		end
	end
	if btn.SetTemplate then btn:SetTemplate("Default") end
	ColorBorderPersistent(btn)
	if btn.StyleButton then btn:StyleButton() end

	local fs = btn:GetFontString()
	if fs then fs:SetTextColor(1, 0.82, 0) end
end

-- First / last page buttons. ElvUI picks the arrow direction from the button's name, and these are called
-- StartPageButton / EndPageButton, so give each a name that says left / right while it is being skinned.
local function SkinPageArrow(btn, direction)
	if btn.mwArrowSkinned then return end
	btn.mwArrowSkinned = true
	btn.GetName = function() return "MarketWatcherHistoryFrame" .. direction .. "Button" end
	S:HandleNextPrevButton(btn)
	btn.GetName = nil
end

-- Result rows: drop the Blizzard gradient and use the same dark box + border as the item list on the left
local function SkinHistoryRowBackground(btn)
	if btn.mwRowSkinned then return end
	btn.mwRowSkinned = true
	for _, region in ipairs({ btn:GetRegions() }) do
		if region:GetObjectType() == "Texture" then
			local tex = region:GetTexture()
			if type(tex) == "string" and tex:find("UI%-AuctionItemNameFrame") then
				region:SetTexture(nil)
				region:Hide()
			end
		end
	end

	-- The icon and text were laid out for the old 32px art band sitting 2px above the middle of the 37px row, so a
	-- full-height box looked off-centre. Draw the box over that same band instead (textures, so it stays behind the text).
	local bg = (E.media and E.media.backdropcolor) or { 0.1, 0.1, 0.1 }
	local bc = { GetBorderColor() }
	local fill = btn:CreateTexture(nil, "BACKGROUND")
	fill:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
	fill:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 5)
	fill:SetTexture(bg[1], bg[2], bg[3], 1)

	local edges = {}
	for i = 1, 4 do
		edges[i] = btn:CreateTexture(nil, "BORDER")
		edges[i]:SetTexture(bc[1], bc[2], bc[3], 1)
	end
	edges[1]:SetPoint("TOPLEFT", fill, "TOPLEFT"); edges[1]:SetPoint("TOPRIGHT", fill, "TOPRIGHT"); edges[1]:SetHeight(1)
	edges[2]:SetPoint("BOTTOMLEFT", fill, "BOTTOMLEFT"); edges[2]:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT"); edges[2]:SetHeight(1)
	edges[3]:SetPoint("TOPLEFT", fill, "TOPLEFT"); edges[3]:SetPoint("BOTTOMLEFT", fill, "BOTTOMLEFT"); edges[3]:SetWidth(1)
	edges[4]:SetPoint("TOPRIGHT", fill, "TOPRIGHT"); edges[4]:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT"); edges[4]:SetWidth(1)
end

local function SkinHistoryListView()
	local list = _G["MarketWatcherHistoryFrameList"]
	if not list then return end
	for _, child in ipairs({ list:GetChildren() }) do
		if child.IsObjectType and child:IsObjectType("Button") then
			local name = child:GetName() or ""
			if name:find("Sort$") then
				SkinSortHeader(child)
			elseif name:find("StartPageButton$") then
				SkinPageArrow(child, "Left")
			elseif name:find("EndPageButton$") then
				SkinPageArrow(child, "Right")
			elseif name:find("ListButton%d+$") then
				SkinHistoryRowBackground(child)
				AddRowHoverBorder(child)
			end
		end
	end
end

local function SkinMarketWatcher()
	if not AuctionFrame then return end

	SkinAddItemWindow()
	SkinSellOptionsWindow()
	SkinScanStatusWindow()
	SkinUnhideButton()
	SkinFiltersWindow()
	SkinConfigWindow()
	SkinHistoryGraphOptions()
	SkinDropDownCustom()
	SkinHistoryListView()

	-- Clean up both specific scrollbar frames shown in screenshots
	RemoveScrollBarBackdrop("MarketWatcherHistoryFrameItemSelectScrollFrameScrollBar")
	RemoveScrollBarBackdrop("MarketWatcherScanFrameAuctionsScrollFrameScrollBar")

	local recordChk = _G["MarketWatcherScanFrameRecordCheckBox"] or _G["MarketWatcherRecordScansCheckButton"]
	if recordChk then
		SkinCheckBoxCustom(recordChk)
		StyleCheckBoxBorder(recordChk)
	end

	local pageButtons = {
		"MarketWatcherScanFrameAuctionsPrevPageButton",
		"MarketWatcherScanFrameAuctionsNextPageButton"
	}
	for _, btnName in ipairs(pageButtons) do
		local btn = _G[btnName]
		if btn and not btn.isElvUISkinned then
			S:HandleNextPrevButton(btn)
			btn.isElvUISkinned = true
		end
	end

	local actionButtons = {
		"MarketWatcherHistoryFrameAddItemButton",
		"MarketWatcherHistoryFrameConfigButton",
		"MarketWatcherHistoryFrameListGraphButton",
		"MarketWatcherHistoryFrameDeleteButton",
		"MarketWatcherHistoryFrameCloseButton",
		"MarketWatcherHistoryFrameGraphButton",
		"MarketWatcherHistoryFrameListButton",
		"MarketWatcherScanFrameScanButton",
		"MarketWatcherScanFrameApplyFiltersButton",
		"MarketWatcherScanFrameEditFiltersButton",
		"MarketWatcherScanFrameCancelUndercutButton",
		"MarketWatcherScanFrameBuyoutButton",
		"MarketWatcherScanFrameCloseButton",
		"MarketWatcherScanFrameStatusAbortButton",
		"MarketWatcherScanFrameConfigButton",
		"MarketWatcherBuyoutButton",
		"MarketWatcherCloseButton",
		"MarketWatcherConfigButton",
		"MarketWatcherAddButton",
		"MarketWatcherScanButton",
		"MarketWatcherDeleteButton",
		"MarketWatcherGraphButton",
		"MarketWatcherListButton"
	}
	for _, btnName in ipairs(actionButtons) do
		local btn = _G[btnName]
		if btn then
			SkinButtonWithBorder(btn)
		end
	end

	local historyListBtn = _G["MarketWatcherHistoryFrameListButton"] or _G["MarketWatcherListButton"]
	local historyDelBtn = _G["MarketWatcherHistoryFrameDeleteButton"] or _G["MarketWatcherDeleteButton"]
	local historyCloseBtn = _G["MarketWatcherHistoryFrameCloseButton"] or _G["MarketWatcherCloseButton"]
	
	if historyCloseBtn then
		historyCloseBtn:ClearAllPoints()
		historyCloseBtn:SetPoint("BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT", -8, 22)
	end
	if historyDelBtn and historyCloseBtn then
		historyDelBtn:ClearAllPoints()
		historyDelBtn:SetPoint("RIGHT", historyCloseBtn, "LEFT", -4, 0)
		historyDelBtn:SetPoint("BOTTOM", historyCloseBtn, "BOTTOM", 0, 0)
	end
	if historyListBtn and historyDelBtn then
		historyListBtn:ClearAllPoints()
		historyListBtn:SetPoint("RIGHT", historyDelBtn, "LEFT", -4, 0)
		historyListBtn:SetPoint("BOTTOM", historyDelBtn, "BOTTOM", 0, 0)
	end

	local applyFiltersBtn = _G["MarketWatcherScanFrameApplyFiltersButton"]
	local editFiltersBtn = _G["MarketWatcherScanFrameEditFiltersButton"]
	local cancelUndercutBtn = _G["MarketWatcherScanFrameCancelUndercutButton"]

	if applyFiltersBtn then
		applyFiltersBtn:ClearAllPoints()
		applyFiltersBtn:SetPoint("BOTTOMLEFT", AuctionFrame, "BOTTOMLEFT", 185, 16)
	end
	if editFiltersBtn and applyFiltersBtn then
		editFiltersBtn:ClearAllPoints()
		editFiltersBtn:SetPoint("LEFT", applyFiltersBtn, "RIGHT", 4, 0)
	end
	if cancelUndercutBtn and editFiltersBtn then
		cancelUndercutBtn:ClearAllPoints()
		cancelUndercutBtn:SetPoint("LEFT", editFiltersBtn, "RIGHT", 4, 0)
	end

	local scanBuyoutBtn = _G["MarketWatcherScanFrameBuyoutButton"] or _G["MarketWatcherBuyoutButton"]
	local scanCloseBtn = _G["MarketWatcherScanFrameCloseButton"] or _G["MarketWatcherCloseButton"]

	if scanCloseBtn then
		scanCloseBtn:ClearAllPoints()
		scanCloseBtn:SetPoint("BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT", -70, 18)
	end
	if scanBuyoutBtn and scanCloseBtn then
		scanBuyoutBtn:ClearAllPoints()
		scanBuyoutBtn:SetPoint("RIGHT", scanCloseBtn, "LEFT", 0, 0)
	end

	-- Filter buttons sit to the left of the Buyout button (right to left)
	if scanBuyoutBtn then
		if cancelUndercutBtn then
			cancelUndercutBtn:ClearAllPoints()
			cancelUndercutBtn:SetPoint("BOTTOMRIGHT", scanBuyoutBtn, "BOTTOMLEFT", -4, 0)
		end
		if editFiltersBtn and cancelUndercutBtn then
			editFiltersBtn:ClearAllPoints()
			editFiltersBtn:SetPoint("BOTTOMRIGHT", cancelUndercutBtn, "BOTTOMLEFT", 0, 0)
		end
		if applyFiltersBtn and editFiltersBtn then
			applyFiltersBtn:ClearAllPoints()
			applyFiltersBtn:SetPoint("BOTTOMRIGHT", editFiltersBtn, "BOTTOMLEFT", 0, 0)
		end
	end

	local moneyFrame = AuctionFrameMoneyFrame or _G["AuctionFrameMoneyFrame"] or _G["MarketWatcherMoneyFrame"]
	if moneyFrame then
		moneyFrame:ClearAllPoints()
		moneyFrame:SetPoint("BOTTOMLEFT", AuctionFrame, "BOTTOMLEFT", 35, 26)
	end

	local historyFrame = _G["MarketWatcherHistoryFrame"]
	if historyFrame then
		if historyFrame.memoryText then
			historyFrame.memoryText:ClearAllPoints()
			historyFrame.memoryText:SetPoint("BOTTOMLEFT", AuctionFrame, "BOTTOMLEFT", 199, 26)
		end
		for _, region in ipairs({ historyFrame:GetRegions() }) do
			if region and region:IsObjectType("FontString") then
				local txt = region:GetText() or ""
				if txt:find("memory used") or txt:find("Market Watcher") then
					region:ClearAllPoints()
					region:SetPoint("BOTTOMLEFT", AuctionFrame, "BOTTOMLEFT", 199, 26)
				end
			end
		end
	end

	local historyTab = _G["AuctionFrameTabMarketWatcherHistory"]
	local scanTab = _G["AuctionFrameTabMarketWatcherScan"]

	for _, tab in ipairs({ historyTab, scanTab }) do
		if tab and not tab.isElvUISkinned then
			tab:StripTextures(true)
			if tab.SetTemplate then
				tab:SetTemplate("Default", true)
				ColorBorderPersistent(tab)
			end
			if tab.GetTextWidth and tab:GetTextWidth() > 0 then
				tab:Width(tab:GetTextWidth() + 24)
			end
			tab.isElvUISkinned = true
		end
	end

	if historyTab and scanTab then
		scanTab:ClearAllPoints()
		scanTab:SetPoint("LEFT", historyTab, "RIGHT", 6, 0)
	end

	local parentPanels = {
		_G["MarketWatcherHistoryFrame"],
		_G["MarketWatcherScanFrame"],
		_G["MarketWatcherFrame"]
	}
	for _, frame in ipairs(parentPanels) do
		if frame then
			SkinMarketWatcherElements(frame)
			StripAllScrollBars(frame)
		end
	end
end

-- ---------------------------------------------------------------------------
-- Edit Filters dialog: make sure its text boxes can take clicks and typing
-- The skin gives every edit box an ElvUI backdrop frame. If anything ends up sitting on top of an edit box
-- (its own backdrop, or a sibling frame at the same level), the box never receives the mouse click and so
-- never gets keyboard focus. Lift each edit box above its siblings and make the backdrop click-through.
-- ---------------------------------------------------------------------------
local function FixEditBoxInput(eb)
	if not eb or not eb.IsObjectType or not eb:IsObjectType("EditBox") then return end
	local parent = eb:GetParent()
	local base = parent and parent:GetFrameLevel() or 0
	eb:SetFrameLevel(base + 10)
	eb:EnableMouse(true)
	eb:EnableKeyboard(true)
	eb:SetAutoFocus(false)
	if eb.backdrop then
		local bd = eb.backdrop
		bd:EnableMouse(false)
		-- The ElvUI border frame paints its dark fill over the typed text, and no frame level fixes that here.
		-- Keep the border line, make its fill see-through, and draw the fill on the edit box itself, behind its text.
		local c = (E.media and E.media.backdropcolor) or { 0.1, 0.1, 0.1 }
		if bd.SetBackdropColor then bd:SetBackdropColor(c[1], c[2], c[3], 0) end
		if bd.SetBackdropBorderColor then bd:SetBackdropBorderColor(0, 0, 0, 0) end -- our own border below replaces it
		if not eb.mwFill then
			eb.mwFill = eb:CreateTexture(nil, "BACKGROUND")
			eb.mwFill:SetAllPoints(eb)
		end
		eb.mwFill:SetTexture(c[1], c[2], c[3], 1)

		-- 1px border drawn just outside the box (thin lines, so they never cover the text)
		if not eb.mwBorder then
			local b = {}
			for i = 1, 4 do b[i] = eb:CreateTexture(nil, "OVERLAY") end
			b[1]:SetPoint("TOPLEFT", eb, "TOPLEFT", -1, 1);       b[1]:SetPoint("TOPRIGHT", eb, "TOPRIGHT", 1, 1);       b[1]:SetHeight(1)
			b[2]:SetPoint("BOTTOMLEFT", eb, "BOTTOMLEFT", -1, -1); b[2]:SetPoint("BOTTOMRIGHT", eb, "BOTTOMRIGHT", 1, -1); b[2]:SetHeight(1)
			b[3]:SetPoint("TOPLEFT", eb, "TOPLEFT", -1, 1);       b[3]:SetPoint("BOTTOMLEFT", eb, "BOTTOMLEFT", -1, -1); b[3]:SetWidth(1)
			b[4]:SetPoint("TOPRIGHT", eb, "TOPRIGHT", 1, 1);      b[4]:SetPoint("BOTTOMRIGHT", eb, "BOTTOMRIGHT", 1, -1); b[4]:SetWidth(1)
			eb.mwBorder = b
			eb:SetTextInsets(3, 3, 0, 0) -- keep the text off the border
		end
		for i = 1, 4 do
			local r, g, b = GetBorderColor()
			eb.mwBorder[i]:SetTexture(r, g, b, 1)
		end
	end
	if not eb.mwFocusHooked then
		eb.mwFocusHooked = true
		-- clicking anywhere on the skinned box focuses it
		eb:HookScript("OnMouseDown", function(self) self:SetFocus() end)
		eb:HookScript("OnEscapePressed", function(self) self:ClearFocus() end)
	end
end

-- Gold / silver / copper rows: the coin icons are textures on the edit boxes. With the skinned boxes they ended up
-- overlapping the neighbouring box, so put each icon just right of its own box and space the next box after it.
local function FindCoinIcon(eb)
	for _, reg in ipairs({ eb:GetRegions() }) do
		if reg:GetObjectType() == "Texture" then
			local tex = reg:GetTexture()
			if type(tex) == "string" and tex:find("UI%-MoneyIcons") then return reg end
		end
	end
end

local function FixMoneyWidgets()
	local f = EnumerateFrames()
	while f do
		local name = f.GetName and f:GetName()
		if name and name:find("^MarketWatcher.*Gold$") and f:IsObjectType("EditBox") then
			-- the Edit Item rows hug the right edge of their window, so they get tighter spacing
			local GAP_BOX_ICON, GAP_ICON_NEXT = 6, 10
			if name:find("EditItemFrame") then GAP_BOX_ICON, GAP_ICON_NEXT = 4, 5 end
			local base = name:gsub("Gold$", "")
			local gold, silver, copper = f, _G[base .. "Silver"], _G[base .. "Copper"]
			local prev
			for _, eb in ipairs({ gold, silver, copper }) do
				if eb then
					local icon = FindCoinIcon(eb)
					if icon then
						icon:ClearAllPoints()
						icon:SetPoint("LEFT", eb, "RIGHT", GAP_BOX_ICON, 0)
						icon:SetDrawLayer("OVERLAY")
					end
					if prev and prev.icon then
						eb:ClearAllPoints()
						eb:SetPoint("LEFT", prev.icon, "RIGHT", GAP_ICON_NEXT, 0)
					end
					prev = { icon = icon }
				end
			end
		end
		f = EnumerateFrames(f)
	end
end

local function FixFilterDialog()
	local f = EnumerateFrames()
	while f do
		if f.IsObjectType and f:IsObjectType("EditBox") and f:IsVisible() and InsideMarketWatcher(f) then
			FixEditBoxInput(f)
		end
		f = EnumerateFrames(f)
	end
	FixMoneyWidgets()
	SkinFilterCheckBoxes()
end

-- /mwdebug : leave the mouse resting on a text box that shows no text, then type this.
-- It lists every visible frame under the cursor, top-most first, and logs focus changes on the edit boxes.
local mwOrder = { BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5, FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8 }
SLASH_MWDEBUG1 = "/mwdebug"
SlashCmdList["MWDEBUG"] = function()
	local say = function(m) DEFAULT_CHAT_FRAME:AddMessage("|cffffd100MW|r " .. m) end
	local list = {}
	local f = EnumerateFrames()
	while f do
		if f.IsVisible and f:IsVisible() and f.IsMouseOver and f:IsMouseOver() and f ~= WorldFrame and f ~= UIParent then
			list[#list + 1] = f
		end
		f = EnumerateFrames(f)
	end
	table.sort(list, function(x, y)
		local sx, sy = mwOrder[x:GetFrameStrata()] or 0, mwOrder[y:GetFrameStrata()] or 0
		if sx ~= sy then return sx > sy end
		return x:GetFrameLevel() > y:GetFrameLevel()
	end)
	say("frames under the cursor, top-most first:")
	for i = 1, math.min(#list, 18) do
		local fr = list[i]
		local bd = fr.GetBackdrop and fr:GetBackdrop()
		say(string.format("  %s [%s] %s lvl=%d mouse=%s backdrop=%s alpha=%.2f", tostring(fr:GetName() or "<unnamed>"),
			fr:GetObjectType(), fr:GetFrameStrata(), fr:GetFrameLevel(), tostring(fr:IsMouseEnabled()),
			tostring(bd and (bd.bgFile or bd.edgeFile) and "yes" or "no"), fr:GetAlpha()))
	end

	-- details of the edit box under the cursor
	for _, fr in ipairs(list) do
		if fr:IsObjectType("EditBox") then
			local font, size, flags = fr:GetFont()
			local r, g, b, a = fr:GetTextColor()
			local l, rr, t, bb = fr:GetTextInsets()
			say(string.format("box %s: w=%.0f h=%.0f font=%s size=%s flags=%s color=%.2f,%.2f,%.2f,%.2f insets=%s,%s,%s,%s justify=%s",
				tostring(fr:GetName()), fr:GetWidth(), fr:GetHeight(), tostring(font), tostring(size), tostring(flags),
				r or -1, g or -1, b or -1, a or -1, tostring(l), tostring(rr), tostring(t), tostring(bb), tostring(fr:GetJustifyH())))
			local bdf = fr.backdrop
			if bdf then
				local bp = bdf:GetParent()
				local bc = { bdf.GetBackdropColor and bdf:GetBackdropColor() }
				say(string.format("backdrop: parent=%s lvl=%d strata=%s fillalpha=%s mwFill=%s",
					tostring(bp and (bp:GetName() or "<unnamed>")), bdf:GetFrameLevel(), bdf:GetFrameStrata(),
					tostring(bc[4]), tostring(fr.mwFill and "yes" or "no")))
			else
				say("backdrop: none on this box")
			end
			for i, reg in ipairs({ fr:GetRegions() }) do
				local ot = reg:GetObjectType()
				local info = ot
				if ot == "FontString" then
					info = info .. " text=[" .. tostring(reg:GetText()) .. "] shown=" .. tostring(reg:IsShown()) .. " alpha=" .. string.format("%.2f", reg:GetAlpha())
				elseif ot == "Texture" then
					info = info .. " tex=" .. tostring(reg:GetTexture()) .. " shown=" .. tostring(reg:IsShown()) .. " layer=" .. tostring(reg:GetDrawLayer())
				end
				say("  region " .. i .. ": " .. info)
			end
			break
		end
	end

	-- log focus changes so we can see whether a box keeps focus after a click
	local g = EnumerateFrames()
	while g do
		if g.IsObjectType and g:IsObjectType("EditBox") and InsideMarketWatcher(g) and not g.mwDebugHooked then
			g.mwDebugHooked = true
			local n = g:GetName() or "<unnamed>"
			g:HookScript("OnEditFocusGained", function() say("focus GAINED " .. n) end)
			g:HookScript("OnEditFocusLost", function() say("focus LOST " .. n) end)
		end
		g = EnumerateFrames(g)
	end
	say("focus logging on: now click a box, type a digit, and tell me which GAINED/LOST lines appear.")
end

-- A long item name ran under the "Scan Summary Options" panel, which is now a solid box and cuts the name off.
-- Shrink the name's font until it fits between the icon and whatever frame sits to its right.
local function FitEditItemName(frame)
	local fs = _G["MarketWatcherHistoryEditItemFrameText"]
	if not fs then return end
	if not frame.mwNameFont then
		local f, sz, fl = fs:GetFont()
		frame.mwNameFont = { f, sz, fl }
	end
	local f, sz, fl = frame.mwNameFont[1], frame.mwNameFont[2], frame.mwNameFont[3]

	local fsLeft, fsTop, fsBottom = fs:GetLeft(), fs:GetTop(), fs:GetBottom()
	if not fsLeft then return end

	local limit
	for _, child in ipairs({ frame:GetChildren() }) do
		if child:IsShown() and child:IsObjectType("Frame")
			and not child:IsObjectType("Button") and not child:IsObjectType("EditBox") then
			local l, t, b = child:GetLeft(), child:GetTop(), child:GetBottom()
			if l and t and b and l > fsLeft and t >= fsBottom and b <= fsTop and (not limit or l < limit) then
				limit = l
			end
		end
	end
	if not limit then return end

	local avail = limit - fsLeft - 8
	if fs.SetWordWrap then fs:SetWordWrap(false) end
	fs:SetWidth(0) -- measure the natural width of the text
	local size = sz
	fs:SetFont(f, size, fl)
	while size > 8 and fs:GetStringWidth() > avail do
		size = size - 1
		fs:SetFont(f, size, fl)
	end
	fs:SetWidth(avail)
end

-- Skin the Edit Item window (right-click an item on the History page).
-- Not StripTextures: the item icon is a texture on this frame, so only the dialog art is removed.
local function SkinEditItemWindow()
	local frame = _G["MarketWatcherHistoryEditItemFrame"]
	if not frame then return end

	if not frame.isElvUISkinned then
		local icon = _G["MarketWatcherHistoryEditItemFrameIcon"]
		for _, region in ipairs({ frame:GetRegions() }) do
			if region:GetObjectType() == "Texture" and region ~= icon then
				region:SetTexture(nil)
				region:Hide()
			end
		end
		if icon then icon:SetTexCoord(unpack(E.TexCoords)) end

		frame:SetTemplate("Default")
		local bg = (E.media and E.media.backdropcolor) or { 0.1, 0.1, 0.1 }
		frame:SetBackdropColor(bg[1], bg[2], bg[3], 1)
		ColorBorder(frame)

		local title = _G["MarketWatcherHistoryEditItemFrameTitle"]
		if title then
			title:ClearAllPoints()
			title:SetPoint("TOP", frame, "TOP", 0, -8)
		end

		frame.isElvUISkinned = true
	end

	local function Walk(parent)
		for _, child in ipairs({ parent:GetChildren() }) do
			local name = child:GetName() or ""

			if child:IsObjectType("EditBox") then
				if not child.isElvUISkinned then
					SkinEditBox(child)
					child.isElvUISkinned = true
				end
				FixEditBoxInput(child)

			elseif child:IsObjectType("CheckButton") then
				if name:find("Radio") then
					if not child.isElvUISkinned then
						if S.HandleRadioButton then S:HandleRadioButton(child) end
						child.isElvUISkinned = true
					end
				else
					SkinCheckBoxCustom(child)
					StyleCheckBoxBorder(child)
				end

			elseif child:IsObjectType("Button") then
				if not child.isElvUISkinned and name:find("Button$") then
					SkinButtonWithBorder(child)
				end

			elseif child:IsObjectType("Frame") and not child.isElvUISkinned and child:GetParent() == frame then
				-- the two unnamed option panels (summary options / history recording options)
				local bd = child.GetBackdrop and child:GetBackdrop()
				if bd and bd.edgeFile and bd.edgeFile:find("UI%-Tooltip%-Border") then
					child:SetTemplate("Default")
					ColorBorder(child)
					child.isElvUISkinned = true
				end
			end

			Walk(child)
		end
	end
	Walk(frame)

	FixMoneyWidgets()
	FitEditItemName(frame)
end

-- These frames usually don't exist yet when this file loads, so hook them lazily (once)
local SkinPass

local function AttachHooks()
	local addBtn = _G["MarketWatcherHistoryFrameAddItemButton"]
	if addBtn and not addBtn.mwHooked then
		addBtn.mwHooked = true
		addBtn:HookScript("OnClick", function()
			C_Timer.After(0.01, SkinAddItemWindow)
		end)
	end

	local mwHistory = MarketWatcher and MarketWatcher.History
	if mwHistory and not mwHistory.mwSkinHooked then
		mwHistory.mwSkinHooked = true
		for _, fname in ipairs({ "CreateGraphButtons", "RenderGraph" }) do
			if type(mwHistory[fname]) == "function" then
				hooksecurefunc(mwHistory, fname, function()
					if IsSkinEnabled() then SkinHistoryGraphOptions() end
				end)
			end
		end
	end

	local editItemFrame = _G["MarketWatcherHistoryEditItemFrame"]
	if editItemFrame and not editItemFrame.mwHooked then
		editItemFrame.mwHooked = true
		editItemFrame:HookScript("OnShow", function()
			SkinEditItemWindow()
			C_Timer.After(0.05, SkinEditItemWindow)
		end)
	end

	local configFrame = _G["MarketWatcherConfigFrame"]
	if configFrame and not configFrame.mwHooked then
		configFrame.mwHooked = true
		configFrame:HookScript("OnShow", function()
			SkinConfigWindow()
			C_Timer.After(0.05, SkinConfigWindow)
		end)
	end

	local filtersFrame = _G["MarketWatcherFiltersFrame"]
	if filtersFrame and not filtersFrame.mwHooked then
		filtersFrame.mwHooked = true
		filtersFrame:HookScript("OnShow", function()
			SkinFiltersWindow()
			C_Timer.After(0.01, FixFilterDialog)
			C_Timer.After(0.2, FixFilterDialog)
		end)
		if filtersFrame:IsShown() then FixFilterDialog() end
	end

	local editFiltersBtn = _G["MarketWatcherScanFrameEditFiltersButton"]
	if editFiltersBtn and not editFiltersBtn.mwHooked then
		editFiltersBtn.mwHooked = true
		editFiltersBtn:HookScript("OnClick", function()
			C_Timer.After(0.01, FixFilterDialog)
			C_Timer.After(0.2, FixFilterDialog)
		end)
	end

	local scanBtn = _G["MarketWatcherScanFrameScanButton"] or _G["MarketWatcherScanButton"]
	if scanBtn and not scanBtn.mwHooked then
		scanBtn.mwHooked = true
		scanBtn:HookScript("OnClick", function()
			C_Timer.After(0.05, SkinScanStatusWindow)
			C_Timer.After(2, SkinPass)
		end)
	end

	local scanScroll = _G["MarketWatcherScanFrameAuctionsScrollFrame"]
	if scanScroll and not scanScroll.mwHooked then
		scanScroll.mwHooked = true
		scanScroll:HookScript("OnVerticalScroll", function()
			C_Timer.After(0.01, SkinSellOptionsWindow)
			StripAllScrollBars(_G["MarketWatcherScanFrame"])
		end)
	end

	local historyScroll = _G["MarketWatcherHistoryFrameItemSelectScrollFrame"]
	if historyScroll and not historyScroll.mwHooked then
		historyScroll.mwHooked = true
		historyScroll:HookScript("OnVerticalScroll", function()
			StripAllScrollBars(_G["MarketWatcherHistoryFrame"])
		end)
	end

	for _, tabName in ipairs({ "AuctionFrameTabMarketWatcherHistory", "AuctionFrameTabMarketWatcherScan" }) do
		local tab = _G[tabName]
		if tab and not tab.mwHooked then
			tab.mwHooked = true
			tab:HookScript("OnClick", function()
				C_Timer.After(0.05, SkinPass)
			end)
		end
	end
end

SkinPass = function()
	if not IsSkinEnabled() then return end -- switched off in the AddOn Skins options
	SkinMarketWatcher()
	AttachHooks()
end

local function RunSkinningPasses()
	SkinPass()
	C_Timer.After(0.05, SkinPass)
	C_Timer.After(0.15, SkinPass)
	C_Timer.After(0.3, SkinPass)
end

local f = CreateFrame("Frame")
f:RegisterEvent("AUCTION_HOUSE_SHOW")
f:SetScript("OnEvent", function()
	RunSkinningPasses()
end)

if AuctionFrame then
	AuctionFrame:HookScript("OnShow", function()
		RunSkinningPasses()
	end)
end

for i = 1, 10 do
	local ahTab = _G["AuctionFrameTab"..i]
	if ahTab then
		ahTab:HookScript("OnClick", function()
			RunSkinningPasses()
		end)
	end
end