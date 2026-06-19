local M = {}

local function resetTable(t)
	for k in pairs(t) do
		t[k] = nil
	end
end

local profSpecs = {
	configForSkillLine = { [2881] = 101 },
	tabsForSkillLine = { [2881] = { 201 } },
	tabInfo = {
		[201] = { rootNodeID = 301, name = "Over-LODED", description = "Master unexpected mining." },
	},
	children = {
		[301] = { 302 },
		[302] = {},
	},
	perks = {
		[301] = {
			{ perkID = 401, isMajorPerk = false },
		},
		[302] = {
			{ perkID = 402, isMajorPerk = true },
		},
	},
	descriptions = {
		path = {
			[301] = "Unlocks deeper mining techniques.",
			[302] = "Grants bonuses while mining deep veins.",
		},
		perk = {
			[401] = "Minor bonus",
			[402] = "Grants Multicraft while mining",
		},
	},
	states = {
		path = { [301] = 2, [302] = 1 },
		perk = { [401] = 1, [402] = 1 },
	},
	unlockRank = { [401] = 5, [402] = 20 },
}

local traits = {
	nodes = {
		[301] = { currentRank = 1, maxRanks = 2, isVisible = true, activeEntry = { entryID = 911 } },
		[302] = { currentRank = 0, maxRanks = 40, isVisible = true, activeEntry = { entryID = 912 } },
	},
	unlockEntry = { [301] = 901, [302] = 902 },
	spendEntry = { [301] = 911, [302] = 912 },
	entries = {
		[901] = { maxRanks = 1 },
		[902] = { maxRanks = 1 },
		[911] = { definitionID = 1001 },
		[912] = { definitionID = 1002 },
	},
	definitions = {
		[1001] = { overrideName = "Over-LODED Core", spellID = 50001 },
		[1002] = { overrideName = "Deep Veins", spellID = 50002 },
	},
}

function M.reset()
	resetTable(profSpecs.configForSkillLine)
	profSpecs.configForSkillLine[2881] = 101
end

function M.install()
	_G.Enum = _G.Enum or {}
	_G.Enum.ProfessionsSpecPathState = { Locked = 1, Progressing = 2, Completed = 3 }
	_G.Enum.ProfessionsSpecPerkState = { Unearned = 1, Pending = 2, Earned = 3 }

	_G.C_ProfSpecs = {
		SkillLineHasSpecialization = function(skillLineID)
			return skillLineID == 2881
		end,
		GetDefaultSpecSkillLine = function()
			return 2881
		end,
		GetConfigIDForSkillLine = function(skillLineID)
			return profSpecs.configForSkillLine[skillLineID] or 0
		end,
		GetSpecTabIDsForSkillLine = function(skillLineID)
			return profSpecs.tabsForSkillLine[skillLineID] or {}
		end,
		GetTabInfo = function(tabID)
			return profSpecs.tabInfo[tabID]
		end,
		GetChildrenForPath = function(pathID)
			return profSpecs.children[pathID] or {}
		end,
		GetPerksForPath = function(pathID)
			return profSpecs.perks[pathID] or {}
		end,
		GetDescriptionForPath = function(pathID)
			return profSpecs.descriptions.path[pathID]
		end,
		GetDescriptionForPerk = function(perkID)
			return profSpecs.descriptions.perk[perkID]
		end,
		GetStateForPath = function(pathID)
			return profSpecs.states.path[pathID]
		end,
		GetStateForPerk = function(perkID)
			return profSpecs.states.perk[perkID]
		end,
		GetUnlockRankForPerk = function(perkID)
			return profSpecs.unlockRank[perkID]
		end,
		GetSourceTextForPath = function()
			return ""
		end,
		GetUnlockEntryForPath = function(pathID)
			return traits.unlockEntry[pathID]
		end,
		GetSpendEntryForPath = function(pathID)
			return traits.spendEntry[pathID]
		end,
		GetCurrencyInfoForSkillLine = function()
			return { numAvailable = 3 }
		end,
	}

	_G.C_Traits = {
		GetNodeInfo = function(_, nodeID)
			return traits.nodes[nodeID]
		end,
		GetEntryInfo = function(_, entryID)
			return traits.entries[entryID]
		end,
		GetDefinitionInfo = function(definitionID)
			return traits.definitions[definitionID]
		end,
	}

	_G.TalentUtil = {
		GetTalentName = function(overrideName, spellID)
			if overrideName and overrideName ~= "" then
				return overrideName
			end
			return ""
		end,
	}

	_G.C_TradeSkillUI = {
		GetAllProfessionTradeSkillLines = function()
			return { 2881 }
		end,
		GetProfessionInfoBySkillLineID = function(skillLineID)
			if skillLineID == 2881 then
				return { professionName = "Midnight Mining", parentProfessionID = 186 }
			end
		end,
	}

	_G.C_Timer = _G.C_Timer or {
		NewTimer = function(_, fn)
			fn()
			return { Cancel = function() end }
		end,
	}
end

return M
