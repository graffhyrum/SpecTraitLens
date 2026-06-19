local addonName = ...
local STL = _G.SpecTraitLens
if not STL or not STL.Controller or not STL.TraitBrowser then
	return
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, name)
	if event ~= "ADDON_LOADED" or name ~= addonName then
		return
	end
	STL.Controller:ApplyFromSaved()
	STL.MinimapButton:Init()
	STL.Slash:Init()
	STL.ProfessionsHook:Init()
end)
