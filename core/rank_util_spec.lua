local STL = _G.SpecTraitLens

describe("RankUtil (sandbox)", function()
	local RankUtil = STL.RankUtil

	it("subtracts unlock rank from display ranks", function()
		local nodeInfo = { currentRank = 3, maxRanks = 5 }
		local curr, max = RankUtil.GetDisplayRanks(101, 301, nodeInfo)
		assert.are.equal(2, curr)
		assert.are.equal(4, max)
	end)
end)
