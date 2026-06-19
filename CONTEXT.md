# Spec Trait Lens

WoW **retail** addon: searchable index of profession specialization paths and perks.

## Language

**Path**:
A specialization tree node (the dial-center node in Blizzard's UI). Identified by `pathID` via `C_ProfSpecs`.
_Avoid_: node, talent, skill

**Perk / pip**:
A milestone bonus on a path's rank dial. `isMajorPerk` marks a major pip.
_Avoid_: trait point, bonus node

**Tab**:
A specialization branch (e.g. "Over-LODED", "Plentiful Ores"). From `C_ProfSpecs.GetTabInfo`.
_Avoid_: spec tree, specialization page

**Trait index**:
Flat list derived live from `C_ProfSpecs` + `C_Traits` for one profession skill line.
_Avoid_: database, cache file

**Searchable text**:
For paths: path description plus all perk descriptions on that path concatenated. Enables keyword search without expanding rows.
_Avoid_: search index, full text

**Knowledge**:
Unspent specialization currency from `C_ProfSpecs.GetCurrencyInfoForSkillLine`.
_Avoid_: points, KP (unless user-facing shorthand in UI)

## Example dialogue

> "Search for Multicraft in Midnight Mining specs."
> → Open `/stl` or Trait Index in Professions; type `Multicraft`; matching paths and perks appear with parent context.

> "Show only major pips I haven't earned yet."
> → Enable Major pips only + Unearned only filters.
