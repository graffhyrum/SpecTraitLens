local PTS = _G.ProfessionTraitSearch

local RowPresentation = {}
PTS.RowPresentation = RowPresentation

local ROW_MIN = { tab = 36, path = 44, perk = 28 }

local FONT_OBJECT = {
	tab = "GameFontNormalLarge",
	path = "GameFontHighlight",
	perk = "GameFontHighlightSmall",
}

local function fontRGB(fontColor, r, g, b)
	if fontColor and fontColor.GetRGB then
		return fontColor:GetRGB()
	end
	return r, g, b
end

local SEMANTIC_RGB = {
	earned = { fontRGB(GREEN_FONT_COLOR, 0.1, 1, 0.1) },
	inaccessible = { fontRGB(GRAY_FONT_COLOR, 0.5, 0.5, 0.5) },
	nextTrait = { 0.55, 0.78, 1 },
	accessible = { 1, 0.82, 0 },
	neutral = { 1, 1, 1 },
	structural = { 1, 1, 1 },
	muted = { 0.72, 0.72, 0.72 },
}

local SEMANTIC_TINT = {
	earned = { 0.1, 0.45, 0.1, 0.10 },
	nextTrait = { 0.2, 0.4, 0.65, 0.12 },
	accessible = { 0.75, 0.6, 0.1, 0.14 },
	inaccessible = { 0.35, 0.35, 0.35, 0.08 },
	neutral = { 1, 1, 1, 0.05 },
	structural = { 0.75, 0.6, 0.1, 0.14 },
}

function RowPresentation.ProgressSemantic(row)
	return PTS.RowAvailability.ProgressSemantic(row)
end

function RowPresentation.ProgressColor(row)
	local key = RowPresentation.ProgressSemantic(row)
	local rgb = SEMANTIC_RGB[key] or SEMANTIC_RGB.neutral
	return rgb[1], rgb[2], rgb[3], key
end

function RowPresentation.HeaderColor()
	local rgb = SEMANTIC_RGB.accessible
	return rgb[1], rgb[2], rgb[3]
end

function RowPresentation.DetailColor()
	local rgb = SEMANTIC_RGB.muted
	return rgb[1], rgb[2], rgb[3]
end

function RowPresentation.KnowledgeLabelColor(available)
	if available and available > 0 then
		return RowPresentation.HeaderColor()
	end
	return RowPresentation.DetailColor()
end

function RowPresentation.RowTint(row)
	local key = RowPresentation.ProgressSemantic(row)
	return SEMANTIC_TINT[key] or SEMANTIC_TINT.neutral
end

function RowPresentation.MinHeight(row)
	return ROW_MIN[row and row.kind] or ROW_MIN.perk
end

function RowPresentation.FontObject(row)
	return FONT_OBJECT[row and row.kind] or FONT_OBJECT.perk
end

function RowPresentation.PathRankBadge(row)
	if not row or row.kind ~= "path" then
		return nil
	end
	if not row.maxRanks or row.maxRanks <= 0 then
		return nil
	end
	return string.format("%d / %d", row.currentRank or 0, row.maxRanks)
end

function RowPresentation.TitleColor(row)
	if not row then
		return 1, 1, 1
	end
	local r, g, b = RowPresentation.ProgressColor(row)
	return r, g, b
end

function RowPresentation.BadgeColor(row)
	if not row then
		return nil
	end
	if row.kind == "perk" then
		return RowPresentation.TitleColor(row)
	end
	if row.kind == "path" and RowPresentation.PathRankBadge(row) then
		return RowPresentation.TitleColor(row)
	end
	return nil
end
