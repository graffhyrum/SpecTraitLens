dofile("Tests/bootstrap.lua")
local load_addon = require("Tests.helpers.load_addon")

describe("SpecFold", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	local function allRows()
		local PTS = load_addon.pts()
		return PTS.SpecIndex.Build(PTS.ProfessionContext.GetContextForSkillLine(2881))
	end

	it("hides descendants when a specialization is collapsed", function()
		local PTS = load_addon.pts()
		local rows = allRows()
		local tabKey = rows[1].rowKey
		local folded = PTS.SpecFold.Filter(rows, rows, { [tabKey] = true })
		assert.are.equal(1, #folded)
		assert.are.equal("tab", folded[1].kind)
	end)

	it("hides child paths and perks when a sub-specialization is collapsed", function()
		local PTS = load_addon.pts()
		local rows = allRows()
		local rootPath
		for i = 1, #rows do
			if rows[i].pathID == 301 then
				rootPath = rows[i]
				break
			end
		end
		assert.is_true(rootPath ~= nil)
		local folded = PTS.SpecFold.Filter(rows, rows, { [rootPath.rowKey] = true })
		local kinds = {}
		for i = 1, #folded do
			kinds[folded[i].kind] = (kinds[folded[i].kind] or 0) + 1
		end
		assert.are.equal(1, kinds.tab)
		assert.are.equal(1, kinds.path)
		assert.is_nil(kinds.perk)
	end)

	it("applies fold filtering while search is active", function()
		local PTS = load_addon.pts()
		local rows = allRows()
		local tabKey = rows[1].rowKey
		local searchFiltered = PTS.SpecSearch.Filter(rows, { searchText = "multicraft" })
		assert.is_true(#searchFiltered > 1)
		local folded = PTS.SpecFold.Filter(searchFiltered, rows, { [tabKey] = true })
		assert.are.equal(1, #folded)
		assert.are.equal("tab", folded[1].kind)
	end)
end)

describe("Controller fold state", function()
	before_each(function()
		load_addon.reset()
		_G.UnitGUID = function() return "test-guid" end
		load_addon.load_core()
	end)

	it("collapse all then expand all restores full list", function()
		local PTS = load_addon.pts()
		PTS.Controller:RebuildIndex()
		local fullCount = #PTS.Controller:GetVisibleRows()
		PTS.Controller:CollapseAll()
		assert.is_true(#PTS.Controller:GetVisibleRows() < fullCount)
		PTS.Controller:ExpandAll()
		assert.are.equal(fullCount, #PTS.Controller:GetVisibleRows())
	end)

	it("toggle fold on a path hides only its descendants", function()
		local PTS = load_addon.pts()
		PTS.Controller:RebuildIndex()
		local rows = PTS.Controller:GetVisibleRows()
		local rootPath
		for i = 1, #rows do
			if rows[i].pathID == 301 then
				rootPath = rows[i]
				break
			end
		end
		PTS.Controller:ToggleFold(rootPath.rowKey)
		local folded = PTS.Controller:GetVisibleRows()
		local hasDeepPath = false
		for i = 1, #folded do
			if folded[i].pathID == 302 then
				hasDeepPath = true
			end
		end
		assert.is_false(hasDeepPath)
	end)
end)
