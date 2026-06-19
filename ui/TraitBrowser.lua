local STL = _G.SpecTraitLens

local TraitBrowser = {}
STL.TraitBrowser = TraitBrowser

local ROW_HEIGHT_TAB = 28
local ROW_HEIGHT_PATH = 56
local ROW_HEIGHT_PERK = 44

local instances = {}

local function rowHeight(row)
	if row.kind == "tab" then
		return ROW_HEIGHT_TAB
	elseif row.kind == "path" then
		return ROW_HEIGHT_PATH
	end
	return ROW_HEIGHT_PERK
end

local function stateColor(row)
	if row.kind == "perk" then
		if row.isEarned then
			return 1, 0.82, 0
		end
		return 0.6, 0.6, 0.6
	end
	if row.kind == "path" and row.isCompleted then
		return 0.4, 1, 0.4
	end
	return 1, 1, 1
end

local function createRow(parent, index)
	local f = CreateFrame("Frame", nil, parent)
	f:SetHeight(ROW_HEIGHT_PATH)
	f:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * ROW_HEIGHT_PATH))
	f:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

	f.name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.name:SetPoint("TOPLEFT", 8, -4)
	f.name:SetJustifyH("LEFT")
	f.name:SetWidth(420)

	f.detail = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.detail:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, -2)
	f.detail:SetJustifyH("LEFT")
	f.detail:SetWidth(420)
	f.detail:SetMaxLines(3)

	f.badge = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.badge:SetPoint("TOPRIGHT", -8, -4)

	return f
end

local function layoutRows(browser)
	local rows = STL.Controller:GetVisibleRows()
	local content = browser.content
	local y = 0
	local pool = browser.pool
	local used = 0

	for i = 1, #rows do
		used = used + 1
		local rowFrame = pool[used]
		if not rowFrame then
			rowFrame = createRow(content, used)
			pool[used] = rowFrame
		end
		local row = rows[i]
		local h = rowHeight(row)
		rowFrame:ClearAllPoints()
		rowFrame:SetPoint("TOPLEFT", content, "TOPLEFT", (row.depth or 0) * 16, -y)
		rowFrame:SetPoint("RIGHT", content, "RIGHT", 0, 0)
		rowFrame:SetHeight(h)
		rowFrame:Show()

		local r, g, b = stateColor(row)
		rowFrame.name:SetTextColor(r, g, b)
		rowFrame.detail:SetTextColor(0.8, 0.8, 0.8)

		if row.kind == "tab" then
			rowFrame.name:SetFontObject("GameFontNormalLarge")
			rowFrame.name:SetText(row.name or "")
			rowFrame.detail:SetText(row.description or "")
			rowFrame.badge:SetText("")
		elseif row.kind == "path" then
			rowFrame.name:SetFontObject("GameFontHighlight")
			local rank = ""
			if row.maxRanks and row.maxRanks > 0 then
				rank = string.format(" (%d/%d)", row.currentRank or 0, row.maxRanks)
			end
			rowFrame.name:SetText((row.name or "Path") .. rank)
			rowFrame.detail:SetText(row.description or "")
			rowFrame.badge:SetText("")
		else
			rowFrame.name:SetFontObject("GameFontHighlightSmall")
			local prefix = row.isMajorPerk and "[Major] " or ""
			local unlock = row.unlockRank and (" @ rank " .. row.unlockRank) or ""
			rowFrame.name:SetText(prefix .. (row.name or "Perk") .. unlock)
			rowFrame.detail:SetText(row.description or "")
			rowFrame.badge:SetText(row.isEarned and "Earned" or "")
		end

		rowFrame.pathID = row.pathID
		y = y + h + 4
	end

	for i = used + 1, #pool do
		pool[i]:Hide()
	end

	content:SetHeight(math.max(y, 1))
end

local function buildChrome(browser)
	if browser.built then
		return
	end
	browser.built = true

	local header = browser:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	header:SetPoint("TOPLEFT", 16, -12)
	browser.header = header

	local search = CreateFrame("EditBox", nil, browser, "InputBoxTemplate")
	search:SetSize(280, 20)
	search:SetPoint("TOPLEFT", 16, -36)
	search:SetAutoFocus(false)
	search:SetScript("OnTextChanged", function(self)
		STL.Controller:SetSearchText(self:GetText())
	end)
	search:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	browser.search = search

	local major = CreateFrame("CheckButton", nil, browser, "UICheckButtonTemplate")
	major:SetPoint("TOPLEFT", 16, -64)
	major.text = major:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	major.text:SetPoint("LEFT", major, "RIGHT", 2, 0)
	major.text:SetText("Major pips only")
	major:SetScript("OnClick", function(self)
		STL.Controller:SetMajorPipsOnly(self:GetChecked())
	end)
	browser.major = major

	local unearned = CreateFrame("CheckButton", nil, browser, "UICheckButtonTemplate")
	unearned:SetPoint("TOPLEFT", 180, -64)
	unearned.text = unearned:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	unearned.text:SetPoint("LEFT", unearned, "RIGHT", 2, 0)
	unearned.text:SetText("Unearned only")
	unearned:SetScript("OnClick", function(self)
		STL.Controller:SetUnearnedOnly(self:GetChecked())
	end)
	browser.unearned = unearned

	local scroll = CreateFrame("ScrollFrame", nil, browser, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 8, -92)
	scroll:SetPoint("BOTTOMRIGHT", -28, 8)
	browser.scroll = scroll

	local content = CreateFrame("Frame", nil, scroll)
	content:SetWidth(460)
	scroll:SetScrollChild(content)
	browser.content = content
	browser.pool = {}

	STL.Controller.RegisterCallback(function()
		if browser:IsShown() then
			TraitBrowser:Update(browser)
		end
	end)
end

function TraitBrowser.Update(browser)
	buildChrome(browser)
	local ctx = STL.Controller:GetContext()
	local kp = STL.Controller:GetKnowledgeAvailable()
	if ctx then
		browser.header:SetText(string.format("%s — Knowledge: %d", ctx.professionName, kp))
	else
		browser.header:SetText("No profession specialization available")
	end
	browser.search:SetText(STL.Controller:GetSearchText())
	browser.major:SetChecked(STL.Controller:GetMajorPipsOnly())
	browser.unearned:SetChecked(STL.Controller:GetUnearnedOnly())
	layoutRows(browser)
end

function TraitBrowser:CreateStandalone()
	if self.standalone then
		return self.standalone
	end
	local f = CreateFrame("Frame", "SpecTraitLensBrowser", UIParent, "BackdropTemplate")
	f:SetSize(500, 600)
	f:SetPoint("CENTER")
	f:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})
	f:SetBackdropColor(0, 0, 0, 0.92)
	f:Hide()
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetScript("OnShow", function()
		STL.Controller:SetListening(true)
		STL.Controller:Refresh()
		TraitBrowser:Update(f)
	end)
	f:SetScript("OnHide", function()
		STL.Controller:SetListening(false)
	end)

	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)

	self.standalone = f
	instances[#instances + 1] = f
	return f
end

function TraitBrowser:CreateEmbedded(parent)
	if self.embedded then
		return self.embedded
	end
	local f = CreateFrame("Frame", nil, parent)
	f:SetAllPoints(parent)
	f:Hide()
	f:SetScript("OnShow", function()
		STL.Controller:SetListening(true)
		STL.Controller:Refresh()
		TraitBrowser:Update(f)
	end)
	f:SetScript("OnHide", function()
		if not (self.standalone and self.standalone:IsShown()) then
			STL.Controller:SetListening(false)
		end
	end)
	self.embedded = f
	instances[#instances + 1] = f
	return f
end

function TraitBrowser:ToggleStandalone()
	local f = self:CreateStandalone()
	if f:IsShown() then
		f:Hide()
	else
		self:Update(f)
		f:Show()
	end
end

function TraitBrowser:ShowStandalone(searchText)
	local f = self:CreateStandalone()
	if searchText then
		STL.Controller:SetSearchText(searchText)
	end
	self:Update(f)
	f:Show()
end

function TraitBrowser:HideStandalone()
	if self.standalone then
		self.standalone:Hide()
	end
end

function TraitBrowser:SetEmbeddedVisible(visible)
	local embedded = self.embedded
	if not embedded then
		return
	end
	if visible then
		self:Update(embedded)
		embedded:Show()
	else
		embedded:Hide()
	end
end
