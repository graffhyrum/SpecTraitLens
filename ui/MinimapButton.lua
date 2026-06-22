local PTS = _G.ProfessionTraitSearch

local MinimapButton = {}
PTS.MinimapButton = MinimapButton

local ICON = PTS.ADDON_ICON
local ADDON_LABEL = "Profession Trait Search"

local function tooltipText(tooltip)
	if not tooltip or not tooltip.AddLine then
		return
	end
	tooltip:AddLine(ADDON_LABEL)
	tooltip:AddLine("Left-click: specialization index")
	tooltip:AddLine("Right-click: settings")
	local ctx = PTS.Controller:GetContext()
	if ctx then
		tooltip:AddLine(ctx.professionName, 0.4, 1, 0.4)
	end
end

function MinimapButton:Init()
	if self.initialized then
		return
	end
	self.initialized = true

	local db = PTS.Controller:GetSavedDB()
	db.minimap = db.minimap or { hide = false }

	local ldb = LibStub("LibDataBroker-1.1"):NewDataObject("ProfessionTraitSearch", {
		type = "launcher",
		text = ADDON_LABEL,
		icon = ICON,
		OnClick = function(_, button)
			if button == "RightButton" then
				PTS.Settings:Toggle()
			else
				PTS.SpecBrowser:ToggleStandalone()
			end
		end,
		OnTooltipShow = tooltipText,
	})

	local icon = LibStub("LibDBIcon-1.0")
	icon:Register("ProfessionTraitSearch", ldb, db.minimap)
	icon:Show("ProfessionTraitSearch")
end
