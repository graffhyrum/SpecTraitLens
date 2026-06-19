local STL = _G.SpecTraitLens

local MinimapButton = {}
STL.MinimapButton = MinimapButton

local ICON = "Interface\\Icons\\INV_Misc_Book_09"

local function tooltipText(tooltip)
	if not tooltip or not tooltip.AddLine then
		return
	end
	tooltip:AddLine("Spec Trait Lens")
	tooltip:AddLine("Left-click: trait browser")
	tooltip:AddLine("Right-click: settings")
	local ctx = STL.Controller:GetContext()
	if ctx then
		tooltip:AddLine(ctx.professionName, 0.4, 1, 0.4)
	end
end

function MinimapButton:Init()
	if self.initialized then
		return
	end
	self.initialized = true

	SpecTraitLensDB = SpecTraitLensDB or {}
	SpecTraitLensDB.minimap = SpecTraitLensDB.minimap or { hide = false }

	local ldb = LibStub("LibDataBroker-1.1"):NewDataObject("SpecTraitLens", {
		type = "launcher",
		text = "Spec Trait Lens",
		icon = ICON,
		OnClick = function(_, button)
			if button == "RightButton" then
				STL.Settings:Toggle()
			else
				STL.TraitBrowser:ToggleStandalone()
			end
		end,
		OnTooltipShow = tooltipText,
	})

	local icon = LibStub("LibDBIcon-1.0")
	icon:Register("SpecTraitLens", ldb, SpecTraitLensDB.minimap)
	icon:Show("SpecTraitLens")
end
