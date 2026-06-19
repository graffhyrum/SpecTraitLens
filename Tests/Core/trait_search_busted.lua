dofile("Tests/bootstrap.lua")
local load_addon = require("Tests.helpers.load_addon")

describe("TraitIndex", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	it("builds rows for fixture profession", function()
		local stl = load_addon.stl()
		local ctx = stl.ProfessionContext.GetContextForSkillLine(2881)
		local rows = stl.TraitIndex.Build(ctx)
		assert.is_true(#rows >= 4)
		assert.are.equal("tab", rows[1].kind)
	end)

	it("aggregates perk text into path searchableText", function()
		local stl = load_addon.stl()
		local rows = stl.TraitIndex.Build(stl.ProfessionContext.GetContextForSkillLine(2881))
		local deepPath
		for i = 1, #rows do
			if rows[i].pathID == 302 then
				deepPath = rows[i]
				break
			end
		end
		assert.is_true(deepPath ~= nil)
		assert.is_true(deepPath.searchableText:find("Multicraft", 1, true) ~= nil)
	end)
end)

describe("TraitSearch", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	local function allRows()
		local stl = load_addon.stl()
		return stl.TraitIndex.Build(stl.ProfessionContext.GetContextForSkillLine(2881))
	end

	it("matches Multicraft through searchableText", function()
		local stl = load_addon.stl()
		local filtered = stl.TraitSearch.Filter(allRows(), { searchText = "multicraft" })
		assert.is_true(#filtered >= 2)
	end)

	it("filters major pips with ancestor promotion", function()
		local stl = load_addon.stl()
		local filtered = stl.TraitSearch.Filter(allRows(), { majorPipsOnly = true })
		local perks = 0
		for i = 1, #filtered do
			if filtered[i].kind == "perk" then
				perks = perks + 1
				assert.is_true(filtered[i].isMajorPerk)
			end
		end
		assert.are.equal(1, perks)
		assert.is_true(#filtered > 1)
	end)
end)

describe("RankUtil", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	it("subtracts unlock entry ranks", function()
		local curr, max = load_addon.stl().RankUtil.GetDisplayRanks(101, 301, { currentRank = 3, maxRanks = 5 })
		assert.are.equal(2, curr)
		assert.are.equal(4, max)
	end)
end)
