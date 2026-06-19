local STL = _G.SpecTraitLens

describe("TraitIndex (sandbox)", function()
	local TraitIndex = STL.TraitIndex
	local ProfessionContext = STL.ProfessionContext

	it("builds tab path and perk rows", function()
		local ctx = ProfessionContext.GetContextForSkillLine(2881)
		local rows = TraitIndex.Build(ctx)
		assert.is_true(#rows >= 4)
		assert.are.equal("tab", rows[1].kind)
	end)

	it("aggregates perk text into path searchableText", function()
		local ctx = ProfessionContext.GetContextForSkillLine(2881)
		local rows = TraitIndex.Build(ctx)
		local deepPath
		for i = 1, #rows do
			if rows[i].pathID == 302 then
				deepPath = rows[i]
				break
			end
		end
		assert.is_not_nil(deepPath)
		assert.is_true(deepPath.searchableText:find("Multicraft", 1, true) ~= nil)
	end)
end)
