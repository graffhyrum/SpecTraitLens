local STL = _G.SpecTraitLens

local Slash = {}
STL.Slash = Slash

local function printHelp()
	DEFAULT_CHAT_FRAME:AddMessage("|cff33cc99Spec Trait Lens|r — /stl, /stl search <term>, /stl status")
end

local function onSlash(msg)
	msg = strtrim(msg or "")
	local lower = msg:lower()
	if lower == "status" then
		local ctx = STL.Controller:GetContext()
		local name = ctx and ctx.professionName or "none"
		local count = #(STL.Controller:GetVisibleRows())
		DEFAULT_CHAT_FRAME:AddMessage("|cff33cc99Spec Trait Lens|r " .. name .. " — " .. count .. " visible rows")
		return
	end
	if lower:match("^search ") then
		local term = msg:sub(8)
		STL.TraitBrowser:ShowStandalone(term)
		return
	end
	if lower == "help" then
		printHelp()
		return
	end
	STL.TraitBrowser:ToggleStandalone()
end

function Slash:Init()
	SLASH_SPECTRAITLENS1 = "/stl"
	SlashCmdList["SPECTRAITLENS"] = onSlash
end
