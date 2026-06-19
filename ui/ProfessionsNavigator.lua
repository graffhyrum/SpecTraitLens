local PL = _G.PerkLens

local ProfessionsNavigator = {}
PL.ProfessionsNavigator = ProfessionsNavigator

local pendingNav
local navFrame
local beforeNavigate

local function getSpecTabID()
	return ProfessionsFrame and ProfessionsFrame.specializationsTabID
end

local function getSpecPage()
	return ProfessionsFrame and ProfessionsFrame.SpecPage
end

local function selectSpecTab(specPage, tabTreeID)
	if EventRegistry and EventRegistry.TriggerEvent then
		EventRegistry:TriggerEvent("ProfessionsSpecializations.TabSelected", tabTreeID)
	elseif specPage.SetSelectedTab then
		specPage:SetSelectedTab(tabTreeID)
	end
end

local function selectSpecPath(specPage, tabTreeID, pathID)
	if specPage.SetDefaultPath then
		specPage:SetDefaultPath(pathID)
	end
	if specPage.SetDefaultTab then
		specPage:SetDefaultTab(tabTreeID)
	end
	if EventRegistry and EventRegistry.TriggerEvent then
		EventRegistry:TriggerEvent("ProfessionsSpecializations.PathSelected", pathID, true)
	elseif specPage.SetDetailedPanel then
		specPage:SetDetailedPanel(pathID)
	end
end

local function specPageMatchesTarget(specPage, target)
	if not specPage or not specPage.GetProfessionID or not target then
		return false
	end
	return specPage:GetProfessionID() == target.skillLineID
end

local function applySpecNavigation(target)
	local specPage = getSpecPage()
	if not specPageMatchesTarget(specPage, target) then
		return false
	end

	selectSpecTab(specPage, target.tabTreeID)
	if target.pathID then
		selectSpecPath(specPage, target.tabTreeID, target.pathID)
	end
	return true
end

local function professionDataReady()
	return not (C_TradeSkillUI and C_TradeSkillUI.IsDataSourceChanging and C_TradeSkillUI.IsDataSourceChanging())
end

local function ensureSpecTabSelected()
	local specTabID = getSpecTabID()
	if ProfessionsFrame and ProfessionsFrame.SetTab and specTabID then
		ProfessionsFrame:SetTab(specTabID, true)
	end
end

local function getChildSkillLineID()
	local child = C_TradeSkillUI and C_TradeSkillUI.GetChildProfessionInfo and C_TradeSkillUI.GetChildProfessionInfo()
	return child and child.professionID
end

local function getParentProfessionID(skillLineID)
	local info = C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID and C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
	return info and info.parentProfessionID
end

local function isOnTargetParentProfession(skillLineID)
	local parentID = getParentProfessionID(skillLineID)
	if not parentID then
		return false
	end
	local base = C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo and C_TradeSkillUI.GetBaseProfessionInfo()
	return base and base.professionID == parentID
end

local function requestProfessionOpen(skillLineID)
	if getChildSkillLineID() == skillLineID then
		if not ProfessionsFrame:IsShown() and ShowUIPanel then
			ShowUIPanel(ProfessionsFrame)
		end
		return
	end

	if isOnTargetParentProfession(skillLineID) then
		if C_TradeSkillUI.SetProfessionChildSkillLineID then
			C_TradeSkillUI.SetProfessionChildSkillLineID(skillLineID)
		end
		local child = C_TradeSkillUI.GetChildProfessionInfo and C_TradeSkillUI.GetChildProfessionInfo()
		if child and EventRegistry and EventRegistry.TriggerEvent then
			child.openSpecTab = true
			EventRegistry:TriggerEvent("Professions.ProfessionSelected", child)
		end
		if not ProfessionsFrame:IsShown() and ShowUIPanel then
			ShowUIPanel(ProfessionsFrame)
		end
		return
	end

	if ProfessionsFrame.SetOpenRecipeResponse then
		ProfessionsFrame:SetOpenRecipeResponse(skillLineID, nil, true)
	end
	local openID = getParentProfessionID(skillLineID) or skillLineID
	if C_TradeSkillUI and C_TradeSkillUI.OpenTradeSkill then
		C_TradeSkillUI.OpenTradeSkill(openID)
	end
end

local function applyPendingNav()
	local target = pendingNav
	if not target or not ProfessionsFrame or not getSpecTabID() then
		return false
	end

	if not professionDataReady() then
		return false
	end

	local specPage = getSpecPage()
	if not specPageMatchesTarget(specPage, target) then
		return false
	end

	ensureSpecTabSelected()

	if applySpecNavigation(target) then
		pendingNav = nil
		return true
	end
	return false
end

local function ensureNavFrame()
	if navFrame then
		return navFrame
	end
	navFrame = CreateFrame("Frame")
	navFrame:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
	navFrame:SetScript("OnEvent", function()
		applyPendingNav()
	end)
	return navFrame
end

local function schedulePendingNav()
	ensureNavFrame()
	RunNextFrame(function()
		if applyPendingNav() then
			return
		end
		RunNextFrame(applyPendingNav)
	end)
end

function ProfessionsNavigator:SetBeforeNavigate(fn)
	beforeNavigate = fn
end

function ProfessionsNavigator:Navigate(row)
	local target = PL.SpecNavigation and PL.SpecNavigation.ResolveTarget(row)
	if not target then
		return
	end

	if beforeNavigate then
		beforeNavigate(row, target)
	end

	if C_AddOns and C_AddOns.LoadAddOn and not C_AddOns.IsAddOnLoaded("Blizzard_Professions") then
		C_AddOns.LoadAddOn("Blizzard_Professions")
	end

	if not ProfessionsFrame then
		return
	end

	pendingNav = target
	requestProfessionOpen(target.skillLineID)
	schedulePendingNav()
end
