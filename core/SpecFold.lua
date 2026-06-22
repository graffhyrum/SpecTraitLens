local PTS = _G.ProfessionTraitSearch

local SpecFold = {}
PTS.SpecFold = SpecFold

local function buildParentByPathID(rows)
	local parentByPathID = {}
	for i = 1, #rows do
		local row = rows[i]
		if row.kind == "path" and row.pathID then
			parentByPathID[row.pathID] = row.parentPathID
		end
	end
	return parentByPathID
end

local function tabRowKey(tabTreeID)
	return "tab:" .. tostring(tabTreeID)
end

local function pathRowKey(pathID)
	return "path:" .. tostring(pathID)
end

local function isHiddenByFold(row, collapsedKeys, parentByPathID)
	if row.kind ~= "tab" and collapsedKeys[tabRowKey(row.tabTreeID)] then
		return true
	end
	if row.kind == "path" or row.kind == "perk" then
		local pathID = row.parentPathID
		while pathID do
			if collapsedKeys[pathRowKey(pathID)] then
				return true
			end
			pathID = parentByPathID[pathID]
		end
	end
	return false
end

function SpecFold.Filter(rows, allRows, collapsedKeys)
	if not collapsedKeys or not next(collapsedKeys) then
		return rows
	end

	local parentByPathID = buildParentByPathID(allRows)
	local out = {}
	for i = 1, #rows do
		local row = rows[i]
		if not isHiddenByFold(row, collapsedKeys, parentByPathID) then
			out[#out + 1] = row
		end
	end
	return out
end
