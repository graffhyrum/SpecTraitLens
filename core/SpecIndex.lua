local PTS = _G.ProfessionTraitSearch

local SpecIndex = {}
PTS.SpecIndex = SpecIndex

local PATH_LOCKED = Enum and Enum.ProfessionsSpecPathState and Enum.ProfessionsSpecPathState.Locked or 0
local PATH_PROGRESSING = Enum and Enum.ProfessionsSpecPathState and Enum.ProfessionsSpecPathState.Progressing or 1
local PATH_COMPLETED = Enum and Enum.ProfessionsSpecPathState and Enum.ProfessionsSpecPathState.Completed or 2
local PERK_EARNED = Enum and Enum.ProfessionsSpecPerkState and Enum.ProfessionsSpecPerkState.Earned or 2

local function pathIsAccessible(configID, pathID, pathState)
	if pathState == PATH_COMPLETED then
		return false
	end
	if pathState == PATH_LOCKED then
		local unlockEntry = C_ProfSpecs.GetUnlockEntryForPath(pathID)
		return unlockEntry and C_Traits.CanPurchaseRank(configID, pathID, unlockEntry)
	end
	if pathState == PATH_PROGRESSING then
		local spendEntry = C_ProfSpecs.GetSpendEntryForPath(pathID)
		return spendEntry and C_Traits.CanPurchaseRank(configID, pathID, spendEntry)
	end
	return false
end

local function markNextPerk(perkRows, parentRank)
	local nextPerkID
	local sorted = {}
	for i = 1, #perkRows do
		sorted[i] = perkRows[i]
	end
	table.sort(sorted, function(a, b)
		return (a.unlockRank or 0) < (b.unlockRank or 0)
	end)
	for i = 1, #sorted do
		if not sorted[i].isEarned then
			nextPerkID = sorted[i].perkID
			break
		end
	end
	for i = 1, #perkRows do
		perkRows[i].parentPathRank = parentRank
		perkRows[i].isNextPerk = perkRows[i].perkID == nextPerkID
	end
end

local function firstLine(text)
	if not text or text == "" then
		return ""
	end
	local line = text:match("^(.-)\n")
	return line or text
end

local function talentNameFromEntry(configID, entryID)
	if not entryID or not TalentUtil then
		return ""
	end
	local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
	local definitionID = entryInfo and entryInfo.definitionID
	local defInfo = definitionID and C_Traits.GetDefinitionInfo(definitionID)
	if defInfo then
		return TalentUtil.GetTalentName(defInfo.overrideName, defInfo.spellID) or ""
	end
	return ""
end

local function talentNameForPath(configID, pathID, nodeInfo)
	if not TalentUtil then
		return ""
	end
	nodeInfo = nodeInfo or C_Traits.GetNodeInfo(configID, pathID)
	local activeEntryID = nodeInfo and nodeInfo.activeEntry and nodeInfo.activeEntry.entryID
	local name = talentNameFromEntry(configID, activeEntryID)
	if name ~= "" then
		return name
	end
	name = talentNameFromEntry(configID, C_ProfSpecs.GetSpendEntryForPath(pathID))
	if name ~= "" then
		return name
	end
	return talentNameFromEntry(configID, C_ProfSpecs.GetUnlockEntryForPath(pathID))
end

local function pathName(configID, pathID, nodeInfo)
	return talentNameForPath(configID, pathID, nodeInfo)
end

local function walkPath(rows, configID, skillLineID, tabTreeID, pathID, tabName, depth, parentPathID)
	local nodeInfo = C_Traits.GetNodeInfo(configID, pathID)
	local description = C_ProfSpecs.GetDescriptionForPath(pathID) or ""
	local perks = C_ProfSpecs.GetPerksForPath(pathID) or {}
	local perkDescParts = {}
	local perkRows = {}

	for _, perk in ipairs(perks) do
		local perkDescription = C_ProfSpecs.GetDescriptionForPerk(perk.perkID) or ""
		if perkDescription ~= "" then
			perkDescParts[#perkDescParts + 1] = perkDescription
		end
		perkRows[#perkRows + 1] = {
			kind = "perk",
			rowKey = "perk:" .. tostring(perk.perkID),
			skillLineID = skillLineID,
			tabTreeID = tabTreeID,
			tabName = tabName,
			depth = depth + 1,
			parentPathID = pathID,
			pathID = pathID,
			perkID = perk.perkID,
			name = firstLine(perkDescription),
			description = perkDescription,
			searchableText = perkDescription,
			state = C_ProfSpecs.GetStateForPerk(perk.perkID, configID),
			isMajorPerk = perk.isMajorPerk == true,
			unlockRank = C_ProfSpecs.GetUnlockRankForPerk(perk.perkID),
			isEarned = C_ProfSpecs.GetStateForPerk(perk.perkID, configID) == PERK_EARNED,
		}
	end

	local searchableText = description
	if #perkDescParts > 0 then
		searchableText = searchableText .. "\n" .. table.concat(perkDescParts, "\n")
	end

	local currRank, maxRanks = PTS.RankUtil.GetDisplayRanks(configID, pathID, nodeInfo)
	local pathState = C_ProfSpecs.GetStateForPath(pathID, configID)

	markNextPerk(perkRows, currRank)

	rows[#rows + 1] = {
		kind = "path",
		rowKey = "path:" .. tostring(pathID),
		skillLineID = skillLineID,
		tabTreeID = tabTreeID,
		tabName = tabName,
		depth = depth,
		parentPathID = parentPathID,
		pathID = pathID,
		name = pathName(configID, pathID, nodeInfo),
		description = description,
		searchableText = searchableText,
		state = pathState,
		currentRank = currRank,
		maxRanks = maxRanks,
		sourceText = C_ProfSpecs.GetSourceTextForPath(pathID, configID),
		isCompleted = pathState == PATH_COMPLETED,
		isAccessible = pathIsAccessible(configID, pathID, pathState),
	}

	for i = 1, #perkRows do
		rows[#rows + 1] = perkRows[i]
	end

	for _, childID in ipairs(C_ProfSpecs.GetChildrenForPath(pathID) or {}) do
		walkPath(rows, configID, skillLineID, tabTreeID, childID, tabName, depth + 1, pathID)
	end
end

function SpecIndex.Build(context)
	if not context or not context.configID or not context.skillLineID then
		return {}
	end

	local rows = {}
	local configID = context.configID
	local skillLineID = context.skillLineID
	local tabIDs = C_ProfSpecs.GetSpecTabIDsForSkillLine(skillLineID) or {}

	for _, tabTreeID in ipairs(tabIDs) do
		local tabInfo = C_ProfSpecs.GetTabInfo(tabTreeID)
		if tabInfo then
			rows[#rows + 1] = {
				kind = "tab",
				rowKey = "tab:" .. tostring(tabTreeID),
				skillLineID = skillLineID,
				tabName = tabInfo.name,
				tabTreeID = tabTreeID,
				depth = 0,
				name = tabInfo.name,
				description = tabInfo.description or "",
				searchableText = (tabInfo.name or "") .. "\n" .. (tabInfo.description or ""),
			}
			walkPath(rows, configID, skillLineID, tabTreeID, tabInfo.rootNodeID, tabInfo.name, 1, nil)
		end
	end

	return rows
end
