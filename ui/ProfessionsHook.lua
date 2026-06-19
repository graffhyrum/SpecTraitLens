local STL = _G.SpecTraitLens

local ProfessionsHook = {}
STL.ProfessionsHook = ProfessionsHook

local hooked = {}
local indexMode = false
local specTabID

local function isSpecTabActive()
	if not ProfessionsFrame or not specTabID then
		return false
	end
	return ProfessionsFrame.GetTab and ProfessionsFrame:GetTab() == specTabID
end

local function setBlizzardSpecVisible(visible)
	local specPage = ProfessionsFrame and ProfessionsFrame.SpecPage
	if not specPage then
		return
	end
	if specPage.TreeView then
		specPage.TreeView:SetShown(visible)
	end
	if specPage.DetailedView then
		specPage.DetailedView:SetShown(visible)
	end
	if specPage.TreePreview then
		specPage.TreePreview:SetShown(visible)
	end
end

local function applyIndexMode(enabled)
	indexMode = enabled == true
	if not isSpecTabActive() then
		indexMode = false
	end
	setBlizzardSpecVisible(not indexMode)
	STL.TraitBrowser:SetEmbeddedVisible(indexMode)
	if indexMode then
		STL.Controller:InvalidateIndex()
		STL.Controller:Refresh()
	end
end

local function onTabSet(_, frame, tabID)
	if frame ~= ProfessionsFrame then
		return
	end
	if tabID ~= specTabID then
		if indexMode then
			applyIndexMode(false)
		end
		return
	end
	STL.Controller:InvalidateIndex()
	STL.Controller:Refresh()
	if STL.TraitBrowser.embedded and STL.TraitBrowser.embedded:IsShown() then
		STL.TraitBrowser:Update(STL.TraitBrowser.embedded)
	end
end

local function onProfessionsOpen()
	STL.Controller:SetListening(true)
end

local function onProfessionsClose()
	applyIndexMode(false)
	if not (STL.TraitBrowser.standalone and STL.TraitBrowser.standalone:IsShown()) then
		STL.Controller:SetListening(false)
	end
end

local function createToggleButton(specPage)
	if specPage.stlIndexButton then
		return specPage.stlIndexButton
	end
	local btn = CreateFrame("Button", nil, specPage, "UIPanelButtonTemplate")
	btn:SetSize(120, 22)
	btn:SetText("Trait Index")
	if specPage.ViewTreeButton then
		btn:SetPoint("RIGHT", specPage.ViewTreeButton, "LEFT", -8, 0)
	else
		btn:SetPoint("TOPRIGHT", specPage, "TOPRIGHT", -24, -24)
	end
	btn:SetScript("OnClick", function()
		applyIndexMode(not indexMode)
	end)
	specPage.stlIndexButton = btn
	return btn
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

	if frame.SpecPage then
		createToggleButton(frame.SpecPage)
		STL.TraitBrowser:CreateEmbedded(frame.SpecPage)
	end

	if frame.specializationsTabID then
		specTabID = frame.specializationsTabID
	end
end

function ProfessionsHook:Init()
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
