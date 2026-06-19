dofile("Tests/bootstrap.lua")
local load_addon = require("Tests.helpers.load_addon")

local function ctx(skillLineID, name)
	return {
		skillLineID = skillLineID,
		configID = skillLineID * 10,
		professionName = name or ("Profession " .. tostring(skillLineID)),
	}
end

local function withStubs(stubMap, fn)
	local saved = {}
	for key, replacement in pairs(stubMap) do
		saved[key] = _G.PerkLens.ProfessionContext[key]
		_G.PerkLens.ProfessionContext[key] = replacement
	end
	local ok, err = pcall(fn)
	for key, original in pairs(saved) do
		_G.PerkLens.ProfessionContext[key] = original
	end
	if not ok then
		error(err)
	end
end

describe("ProfessionContext.ResolveForIndex", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	local cases = {
		{
			name = "preferActive uses active context first",
			preferActive = true,
			charDB = { lastSkillLineID = 2002 },
			active = ctx(2001, "Active"),
			saved = ctx(2002, "Saved"),
			list = { ctx(2003, "Listed") },
			want = 2001,
		},
		{
			name = "preferActive falls back to saved skill line",
			preferActive = true,
			charDB = { lastSkillLineID = 2002 },
			active = nil,
			saved = ctx(2002, "Saved"),
			list = { ctx(2003, "Listed") },
			want = 2002,
		},
		{
			name = "standalone prefers saved skill line over active",
			preferActive = false,
			charDB = { lastSkillLineID = 2002 },
			active = ctx(2001, "Active"),
			saved = ctx(2002, "Saved"),
			list = { ctx(2003, "Listed") },
			want = 2002,
		},
		{
			name = "no saved uses active context",
			preferActive = false,
			charDB = {},
			active = ctx(2001, "Active"),
			saved = nil,
			list = { ctx(2003, "Listed") },
			want = 2001,
		},
		{
			name = "falls back to first listed profession",
			preferActive = false,
			charDB = {},
			active = nil,
			saved = nil,
			list = { ctx(2003, "Listed") },
			want = 2003,
		},
		{
			name = "preferActive retries active after saved miss",
			preferActive = true,
			charDB = { lastSkillLineID = 9999 },
			active = ctx(2001, "Active"),
			saved = nil,
			list = { ctx(2003, "Listed") },
			want = 2001,
		},
		{
			name = "returns nil when no context sources",
			preferActive = false,
			charDB = {},
			active = nil,
			saved = nil,
			list = {},
			want = nil,
		},
	}

	for i = 1, #cases do
		local case = cases[i]
		it(case.name, function()
			local pl = load_addon.pl()
			withStubs({
				GetActiveContext = function()
					return case.active
				end,
				GetContextForSkillLine = function(skillLineID)
					if case.charDB.lastSkillLineID == skillLineID then
						return case.saved
					end
					return nil
				end,
				ListSpecSkillLines = function()
					return case.list
				end,
			}, function()
				local resolved = pl.ProfessionContext.ResolveForIndex(case.charDB, case.preferActive)
				if case.want == nil then
					assert.is_nil(resolved)
				else
					assert.is_true(resolved ~= nil)
					assert.are.equal(case.want, resolved.skillLineID)
				end
			end)
		end)
	end

	it("ignores saved skill line when profession was switched away", function()
		local pl = load_addon.pl()
		local active = ctx(2872, "Midnight Blacksmithing")
		local stale = ctx(2871, "Midnight Alchemy")
		withStubs({
			GetActiveContext = function()
				return active
			end,
			GetContextForSkillLine = function(skillLineID)
				if skillLineID == 2871 then
					return stale
				end
				if skillLineID == 2872 then
					return active
				end
				return nil
			end,
			ListSpecSkillLines = function()
				return { active }
			end,
			IsTrainedSkillLine = function(skillLineID)
				return skillLineID ~= 2871
			end,
		}, function()
			local resolved = pl.ProfessionContext.ResolveForIndex({ lastSkillLineID = 2871 }, false)
			assert.are.equal(2872, resolved.skillLineID)
		end)
	end)
end)

describe("Controller ViewMode", function()
	before_each(function()
		load_addon.reset()
		_G.PerkLensDB = nil
		_G.UnitGUID = function()
			return "test-guid"
		end
		load_addon.load_core()
	end)

	it("embedded view mode prefers active profession context", function()
		local pl = load_addon.pl()
		local active = ctx(2001, "Active")
		local saved = ctx(2002, "Saved")
		withStubs({
			GetActiveContext = function()
				return active
			end,
			GetContextForSkillLine = function(skillLineID)
				if skillLineID == 2002 then
					return saved
				end
				return nil
			end,
			ListSpecSkillLines = function()
				return { saved }
			end,
		}, function()
			pl.Controller:SetViewMode("embedded")
			pl.Controller:GetCharDB().lastSkillLineID = 2002
			pl.Controller:RebuildIndex()
			assert.are.equal(2001, pl.Controller:GetContext().skillLineID)
		end)
	end)

	it("closed view mode prefers saved skill line over active", function()
		local pl = load_addon.pl()
		local active = ctx(2001, "Active")
		local saved = ctx(2002, "Saved")
		withStubs({
			GetActiveContext = function()
				return active
			end,
			GetContextForSkillLine = function(skillLineID)
				if skillLineID == 2002 then
					return saved
				end
				return nil
			end,
			ListSpecSkillLines = function()
				return { saved }
			end,
		}, function()
			pl.Controller:SetViewMode("closed")
			pl.Controller:GetCharDB().lastSkillLineID = 2002
			pl.Controller:RebuildIndex()
			assert.are.equal(2002, pl.Controller:GetContext().skillLineID)
		end)
	end)

	it("does not call ProfessionsHook for context policy", function()
		local pl = load_addon.pl()
		pl.ProfessionsHook = {
			IsIndexMode = function()
				error("core must not call ProfessionsHook:IsIndexMode")
			end,
		}
		pl.Controller:SetViewMode("embedded")
		pl.Controller:RebuildIndex()
	end)
end)

describe("ProfessionContext.ListSpecSkillLines", function()
	before_each(function()
		load_addon.reset()
		load_addon.load_core()
	end)

	local function stubProfessionAPIs(skillLines, professionInfoBySkillLineID, trainedSkillLines)
		_G.C_TradeSkillUI.GetAllProfessionTradeSkillLines = function()
			return skillLines
		end
		_G.C_ProfSpecs.SkillLineHasSpecialization = function()
			return true
		end
		_G.C_ProfSpecs.GetConfigIDForSkillLine = function(skillLineID)
			return skillLineID
		end
		_G.C_TradeSkillUI.GetProfessionInfoBySkillLineID = function(skillLineID)
			return professionInfoBySkillLineID[skillLineID]
		end
		_G.GetProfessions = function()
			return 1, 2
		end
		local trained = trainedSkillLines or {}
		_G.GetProfessionInfo = function(index)
			local skillLine = trained[index]
			if not skillLine then
				return nil
			end
			return "Profession", nil, 1, 100, 0, 0, skillLine
		end
	end

	it("orders professions by expansion newest first (sourceCounter desc)", function()
		local pl = load_addon.pl()
		stubProfessionAPIs({ 2881, 2882, 2883 }, {
			[2881] = {
				professionName = "Dragon Isles Mining",
				sourceCounter = 1,
				parentProfessionID = 186,
			},
			[2882] = {
				professionName = "Khaz Algar Mining",
				sourceCounter = 2,
				parentProfessionID = 186,
			},
			[2883] = {
				professionName = "Midnight Mining",
				sourceCounter = 3,
				parentProfessionID = 186,
			},
		}, { [1] = 186 })

		local list = pl.ProfessionContext.ListSpecSkillLines()
		assert.are.equal(3, #list)
		assert.are.equal(2883, list[1].skillLineID)
		assert.are.equal(2882, list[2].skillLineID)
		assert.are.equal(2881, list[3].skillLineID)
	end)

	it("orders by API list position when sourceCounter is zero", function()
		local pl = load_addon.pl()
		stubProfessionAPIs({ 2881, 2882, 2883 }, {
			[2881] = {
				professionName = "Dragon Isles Mining",
				sourceCounter = 0,
				parentProfessionID = 186,
			},
			[2882] = {
				professionName = "Khaz Algar Mining",
				sourceCounter = 0,
				parentProfessionID = 186,
			},
			[2883] = {
				professionName = "Midnight Mining",
				sourceCounter = 0,
				parentProfessionID = 186,
			},
		}, { [1] = 186 })

		local list = pl.ProfessionContext.ListSpecSkillLines()
		assert.are.equal(2883, list[1].skillLineID)
		assert.are.equal(2882, list[2].skillLineID)
		assert.are.equal(2881, list[3].skillLineID)
	end)

	it("excludes skill lines from switched-away professions", function()
		local pl = load_addon.pl()
		stubProfessionAPIs({ 2883, 2871, 2872 }, {
			[2883] = {
				professionName = "Midnight Mining",
				sourceCounter = 3,
				parentProfessionID = 186,
			},
			[2871] = {
				professionName = "Midnight Alchemy",
				sourceCounter = 3,
				parentProfessionID = 171,
			},
			[2872] = {
				professionName = "Midnight Blacksmithing",
				sourceCounter = 3,
				parentProfessionID = 164,
			},
		}, { [1] = 186, [2] = 164 })

		local list = pl.ProfessionContext.ListSpecSkillLines()
		assert.are.equal(2, #list)
		assert.are.equal(2872, list[1].skillLineID)
		assert.are.equal(2883, list[2].skillLineID)
	end)
end)

describe("Controller standalone profession switch", function()
	before_each(function()
		load_addon.reset()
		_G.PerkLensDB = nil
		_G.UnitGUID = function()
			return "test-guid"
		end
		load_addon.load_core()
	end)

	it("SetSkillLine updates context in standalone view mode", function()
		local pl = load_addon.pl()
		local mining = ctx(2883, "Midnight Mining")
		local alchemy = ctx(2871, "Midnight Alchemy")
		withStubs({
			IsTrainedSkillLine = function()
				return true
			end,
			GetActiveContext = function()
				return mining
			end,
			GetContextForSkillLine = function(skillLineID)
				if skillLineID == 2883 then
					return mining
				end
				if skillLineID == 2871 then
					return alchemy
				end
				return nil
			end,
			ListSpecSkillLines = function()
				return { mining, alchemy }
			end,
		}, function()
			pl.Controller:SetViewMode("standalone")
			pl.Controller:RebuildIndex()
			assert.are.equal(2883, pl.Controller:GetContext().skillLineID)

			pl.Controller:SetSkillLine(2871)
			assert.are.equal(2871, pl.Controller:GetContext().skillLineID)
		end)
	end)
end)
