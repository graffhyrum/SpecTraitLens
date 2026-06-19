local PL = _G.PerkLens

local ProfessionsHook = {}
PL.ProfessionsHook = ProfessionsHook

local hooked = {}
local indexMode = false
local specTabID
local indexTab
local updateIndexTab

local TAB_ICON = "Interface\\Icons\\INV_Misc_Book_09"
local TAB_ANCHOR_X = 0
local TAB_ANCHOR_Y = -128

local SPEC_CORE_KEYS = {
	"TreeView",
	"DetailedView",
	"ButtonsParent",
	"VerticalDivider",
	"TopDivider",
	"PanelFooter",
	"ApplyButton",
	"UnlockTabButton",
	"UndoButton",
	"FxModelScene",
}

local SPEC_STATEFUL_KEYS = {
	"TreePreview",
	"ViewTreeButton",
	"BackToPreviewButton",
	"ViewPreviewButton",
	"BackToFullTreeButton",
}

local function isSpecTabActive()
	if not ProfessionsFrame or not specTabID then
		return false
	end
	return ProfessionsFrame.GetTab and ProfessionsFrame:GetTab() == specTabID
end

local function getSpecPage()
	return ProfessionsFrame and ProfessionsFrame.SpecPage
end

updateIndexTab = function()
	if not indexTab then
		return
	end
	local show = ProfessionsFrame and ProfessionsFrame:IsShown() and isSpecTabActive()
	indexTab:SetShown(show)
	if indexTab.SelectedTexture then
		indexTab.SelectedTexture:SetShown(indexMode)
	end
end

local function setFrameShown(frame, visible)
	if frame then
		frame:SetShown(visible)
	end
end

local function forEachPoolEntry(pool, fn)
	if not pool or not pool.EnumerateActive then
		return
	end
	for entry in pool:EnumerateActive() do
		fn(entry)
	end
end

local function setBlizzardSpecChromeVisible(visible)
	local specPage = getSpecPage()
	if not specPage then
		return
	end

	if visible then
		for i = 1, #SPEC_CORE_KEYS do
			setFrameShown(specPage[SPEC_CORE_KEYS[i]], true)
		end
		for i = 1, #SPEC_STATEFUL_KEYS do
			setFrameShown(specPage[SPEC_STATEFUL_KEYS[i]], false)
		end
	else
		for i = 1, #SPEC_CORE_KEYS do
			setFrameShown(specPage[SPEC_CORE_KEYS[i]], false)
		end
		for i = 1, #SPEC_STATEFUL_KEYS do
			setFrameShown(specPage[SPEC_STATEFUL_KEYS[i]], false)
		end
	end

	forEachPoolEntry(specPage.tabsPool, function(tab)
		tab:SetShown(visible)
	end)
	forEachPoolEntry(specPage.perksPool, function(perk)
		perk:SetShown(visible)
	end)
end

local function restoreBlizzardSpecToCurrentTab()
	local specPage = getSpecPage()
	if not specPage then
		return
	end

	setBlizzardSpecChromeVisible(true)

	local treeID = specPage.GetTalentTreeID and specPage:GetTalentTreeID()
	if treeID then
		if EventRegistry and EventRegistry.TriggerEvent then
			EventRegistry:TriggerEvent("ProfessionsSpecializations.TabSelected", treeID)
		elseif specPage.SetSelectedTab then
			specPage:SetSelectedTab(treeID)
		end
		return
	end

	if specPage.UpdateSelectedTabState then
		specPage:UpdateSelectedTabState()
	end
end

local function restoreBlizzardSpecUI()
	restoreBlizzardSpecToCurrentTab()
end

local function applyIndexMode(enabled)
	local wasIndexMode = indexMode
	indexMode = enabled == true
	if not isSpecTabActive() then
		indexMode = false
	end

	if indexMode then
		setBlizzardSpecChromeVisible(false)
		PL.Controller:SetViewMode("embedded")
		local active = PL.ProfessionContext.GetActiveContext()
		if active then
			PL.Controller:SetSkillLine(active.skillLineID)
		else
			PL.Controller:InvalidateIndex()
			PL.Controller:Refresh()
		end
	else
		if PL.SpecBrowser.standalone and PL.SpecBrowser.standalone:IsShown() then
			PL.Controller:SetViewMode("standalone")
		else
			PL.Controller:SetViewMode("closed")
		end
		if wasIndexMode then
			restoreBlizzardSpecUI()
		else
			setBlizzardSpecChromeVisible(true)
		end
	end

	PL.SpecBrowser:SetEmbeddedVisible(indexMode)
	updateIndexTab()
end

local function onTabSet(_, frame, tabID)
	if frame ~= ProfessionsFrame then
		return
	end
	if tabID ~= specTabID then
		if indexMode then
			applyIndexMode(false)
		else
			updateIndexTab()
		end
		return
	end
	updateIndexTab()
	PL.Controller:InvalidateIndex()
	PL.Controller:Refresh()
	if PL.SpecBrowser.embedded and PL.SpecBrowser.embedded:IsShown() then
		PL.SpecBrowser:Update(PL.SpecBrowser.embedded)
	end
end

local function onProfessionsOpen()
	PL.Controller:SetListening(true)
	updateIndexTab()
end

local function onProfessionsClose()
	applyIndexMode(false)
	updateIndexTab()
	if not (PL.SpecBrowser.standalone and PL.SpecBrowser.standalone:IsShown()) then
		PL.Controller:SetListening(false)
	end
end

local function createIndexSideTab(professionsFrame)
	if indexTab then
		return indexTab
	end
	local tab = CreateFrame("Frame", nil, professionsFrame, "LargeSideTabButtonTemplate")
	tab:SetFrameStrata("HIGH")
	tab:SetPoint("TOPLEFT", professionsFrame, "TOPRIGHT", TAB_ANCHOR_X, TAB_ANCHOR_Y)
	tab.tooltipText = "Specialization Index"
	tab.Icon:SetTexture(TAB_ICON)
	tab.Icon:SetSize(24, 24)
	tab.SelectedTexture:SetShown(false)
	tab:SetCustomOnMouseUpHandler(function(_, button, upInside)
		if button == "LeftButton" and upInside then
			applyIndexMode(not indexMode)
		end
	end)
	indexTab = tab
	return tab
end

local function setupProfessionsFrame(frame)
	if hooked[frame] then
		return
	end
	hooked[frame] = true

	frame:HookScript("OnShow", onProfessionsOpen)
	frame:HookScript("OnHide", onProfessionsClose)

	if EventRegistry and EventRegistry.RegisterCallback then
		EventRegistry:RegisterCallback("ProfessionsFrame.TabSet", onTabSet, frame)
	end

	createIndexSideTab(frame)
	updateIndexTab()
	if frame.SpecPage then
		PL.SpecBrowser:CreateEmbedded(frame.SpecPage)
	end

	if frame.specializationsTabID then
		specTabID = frame.specializationsTabID
	end
end

function ProfessionsHook:Init()
	PL.ProfessionsNavigator:SetBeforeNavigate(function()
		if indexMode then
			applyIndexMode(false)
		end
	end)

	local frame = CreateFrame("Frame")
	frame:RegisterEvent("ADDON_LOADED")
	frame:SetScript("OnEvent", function(_, event, name)
		if event ~= "ADDON_LOADED" or name ~= "Blizzard_Professions" then
			return
		end
		if ProfessionsFrame then
			setupProfessionsFrame(ProfessionsFrame)
			if ProfessionsFrame.specializationsTabID then
				specTabID = ProfessionsFrame.specializationsTabID
			end
		end
	end)

	if C_AddOns and C_AddOns.IsAddOnLoaded("Blizzard_Professions") and ProfessionsFrame then
		setupProfessionsFrame(ProfessionsFrame)
		if ProfessionsFrame.specializationsTabID then
			specTabID = ProfessionsFrame.specializationsTabID
		end
	end
end

function ProfessionsHook:IsIndexMode()
	return indexMode
end
