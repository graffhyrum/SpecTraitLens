local STL = _G.SpecTraitLens

describe("TraitSearch (sandbox)", function()
	local TraitSearch = STL.TraitSearch
	local TraitIndex = STL.TraitIndex
	local ProfessionContext = STL.ProfessionContext

	local function allRows()
		return TraitIndex.Build(ProfessionContext.GetContextForSkillLine(2881))
	end

	it("finds Multicraft via child perk searchableText on path", function()
		local filtered = TraitSearch.Filter(allRows(), { searchText = "Multicraft" })
		local foundPath, foundPerk = false, false
		for i = 1, #filtered do
			if filtered[i].pathID == 302 then
				foundPath = true
			end
			if filtered[i].perkID == 402 then
				foundPerk = true
			end
		end
		assert.is_true(foundPath)
		assert.is_true(foundPerk)
	end)

	it("filters major pips only with ancestor promotion", function()
		local filtered = TraitSearch.Filter(allRows(), { majorPipsOnly = true })
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
