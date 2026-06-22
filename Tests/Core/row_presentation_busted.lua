dofile("Tests/bootstrap.lua")
local load_addon = require("Tests.helpers.load_addon")

describe("RowPresentation", function()
	local rp

	before_each(function()
		load_addon.reset()
		load_addon.load_core()
		rp = load_addon.pts().RowPresentation
	end)

	it("returns row tint by progress semantic", function()
		assert.are.same({ 0.75, 0.6, 0.1, 0.14 }, rp.RowTint({ kind = "tab" }))
		assert.are.same({ 0.1, 0.45, 0.1, 0.10 }, rp.RowTint({ kind = "path", isCompleted = true }))
		assert.are.same({ 1, 1, 1, 0.05 }, rp.RowTint({ kind = "path", isCompleted = false, state = 2 }))
		assert.are.same({ 0.75, 0.6, 0.1, 0.14 }, rp.RowTint({ kind = "path", isAccessible = true, state = 2 }))
		assert.are.same({ 0.35, 0.35, 0.35, 0.08 }, rp.RowTint({ kind = "path", state = 1, isAccessible = false }))
		assert.are.same({ 0.2, 0.4, 0.65, 0.12 }, rp.RowTint({ kind = "perk", isEarned = false, isNextPerk = true }))
	end)

	it("returns min height per kind", function()
		assert.are.equal(36, rp.MinHeight({ kind = "tab" }))
		assert.are.equal(44, rp.MinHeight({ kind = "path" }))
		assert.are.equal(28, rp.MinHeight({ kind = "perk" }))
		assert.are.equal(28, rp.MinHeight({ kind = "unknown" }))
	end)

	it("returns font object per kind", function()
		assert.are.equal("GameFontNormalLarge", rp.FontObject({ kind = "tab" }))
		assert.are.equal("GameFontHighlight", rp.FontObject({ kind = "path" }))
		assert.are.equal("GameFontHighlightSmall", rp.FontObject({ kind = "perk" }))
	end)

	it("formats path rank badge when maxRanks set", function()
		assert.are.equal("2 / 5", rp.PathRankBadge({ kind = "path", currentRank = 2, maxRanks = 5 }))
		assert.are.equal("0 / 3", rp.PathRankBadge({ kind = "path", maxRanks = 3 }))
		assert.is_nil(rp.PathRankBadge({ kind = "path", maxRanks = 0 }))
		assert.is_nil(rp.PathRankBadge({ kind = "tab" }))
	end)

	it("returns title color by row kind and progress", function()
		assert.are.same({ 1, 1, 1 }, { rp.TitleColor({ kind = "tab" }) })
		assert.are.same({ 1, 1, 1 }, { rp.TitleColor({ kind = "path", isCompleted = false, state = 2 }) })
		assert.are.same({ 0.1, 1, 0.1 }, { rp.TitleColor({ kind = "path", isCompleted = true }) })
		assert.are.same({ 0.5, 0.5, 0.5 }, {
			rp.TitleColor({ kind = "perk", isEarned = false, isNextPerk = false, parentPathRank = 0, unlockRank = 5 }),
		})
		assert.are.same({ 0.55, 0.78, 1 }, { rp.TitleColor({ kind = "perk", isEarned = false, isNextPerk = true }) })
		assert.are.same({ 0.1, 1, 0.1 }, { rp.TitleColor({ kind = "perk", isEarned = true }) })
		assert.are.same({ 1, 0.82, 0 }, { rp.TitleColor({ kind = "path", isAccessible = true, state = 2 }) })
	end)

	it("returns badge color aligned with title for path and perk rows", function()
		assert.are.same({ 0.55, 0.78, 1 }, { rp.BadgeColor({ kind = "perk", isEarned = false, isNextPerk = true }) })
		assert.are.same({ 0.1, 1, 0.1 }, { rp.BadgeColor({ kind = "perk", isEarned = true }) })
		assert.are.same({ 1, 0.82, 0 }, { rp.BadgeColor({ kind = "path", maxRanks = 5, isAccessible = true, state = 2 }) })
		assert.is_nil(rp.BadgeColor({ kind = "path", maxRanks = 0 }))
		assert.is_nil(rp.BadgeColor({ kind = "tab" }))
	end)

	it("exposes chrome colors", function()
		assert.are.same({ 0.72, 0.72, 0.72 }, { rp.DetailColor() })
		assert.are.same({ 1, 0.82, 0 }, { rp.HeaderColor() })
		assert.are.same({ 1, 0.82, 0 }, { rp.KnowledgeLabelColor(3) })
		assert.are.same({ 0.72, 0.72, 0.72 }, { rp.KnowledgeLabelColor(0) })
	end)
end)
