dofile("Tests/bootstrap.lua")
local load_addon = require("Tests.helpers.load_addon")

describe("RowAvailability", function()
	local ra

	before_each(function()
		load_addon.reset()
		load_addon.load_core()
		ra = load_addon.pts().RowAvailability
	end)

	it("resolves path semantics", function()
		assert.are.equal("earned", ra.ProgressSemantic({ kind = "path", isCompleted = true }))
		assert.are.equal("accessible", ra.ProgressSemantic({ kind = "path", state = 2, isAccessible = true }))
		assert.are.equal("inaccessible", ra.ProgressSemantic({ kind = "path", state = 1, isAccessible = false }))
		assert.are.equal("neutral", ra.ProgressSemantic({ kind = "path", state = 2, isAccessible = false }))
	end)

	it("resolves perk semantics with priority", function()
		assert.are.equal("earned", ra.ProgressSemantic({ kind = "perk", isEarned = true }))
		assert.are.equal("nextTrait", ra.ProgressSemantic({ kind = "perk", isEarned = false, isNextPerk = true }))
		assert.are.equal("accessible", ra.ProgressSemantic({
			kind = "perk",
			isEarned = false,
			isNextPerk = false,
			state = 2,
			parentPathRank = 10,
			unlockRank = 5,
		}))
		assert.are.equal("inaccessible", ra.ProgressSemantic({
			kind = "perk",
			isEarned = false,
			isNextPerk = false,
			parentPathRank = 1,
			unlockRank = 5,
		}))
	end)

	it("treats tabs as structural", function()
		assert.are.equal("structural", ra.ProgressSemantic({ kind = "tab" }))
	end)
end)
