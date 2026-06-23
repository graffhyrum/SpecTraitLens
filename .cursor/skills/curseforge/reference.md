# CurseForge API reference (PTS)

## Studios REST API (`api.curseforge.com/v1`)

**Auth:** `x-api-token: <token>` (this repo) or `x-api-key` per official Studios docs.

**Common headers:** `Accept: application/json`

### Mods

| Method | Path | Notes |
|--------|------|-------|
| GET | `/mods/search` | Query: `gameId`, `searchFilter`, `slug`, `pageSize`, `index`, `sortField`, `sortOrder` |
| GET | `/mods/{modId}` | Single mod |
| POST | `/mods` | Body: `{ "modIds": [id, ...] }` — batch get |
| GET | `/mods/{modId}/description` | HTML description |
| GET | `/mods/{modId}/files` | Query: `gameVersion`, `modLoaderType`, `index`, `pageSize` |
| GET | `/mods/{modId}/files/{fileId}` | Single file metadata |
| GET | `/mods/{modId}/files/{fileId}/download-url` | Pre-signed download URL |

### Games

| Method | Path | Notes |
|--------|------|-------|
| GET | `/games` | All games |
| GET | `/games/{gameId}/versions` | Version list with IDs |
| GET | `/games/{gameId}/versions/{gameVersionId}` | Single version |
| GET | `/games/{gameId}/modloader` | Mod loaders for game |

WoW retail: `gameId=432`.

### Categories

| Method | Path |
|--------|------|
| GET | `/categories?gameId=432` |
| GET | `/categories/{classId}` |

### Response envelope

Most endpoints return:

```json
{ "data": { ... } }
```

or for lists:

```json
{ "data": [ ... ], "pagination": { "index": 0, "pageSize": 50, "totalCount": 1 } }
```

## Site / upload API (`wow.curseforge.com/api`)

**Auth:** `X-Api-Token: <token>` header or `?token=` query param.

URIs are relative to the game site (`wow.curseforge.com` for WoW).

### Read

| Method | Path | Returns |
|--------|------|---------|
| GET | `/game/versions` | `{ id, gameVersionTypeID, name, slug }[]` |
| GET | `/game/dependencies` | `{ id, name, slug }[]` |

### Upload / update files

| Method | Path | Body |
|--------|------|------|
| POST | `/projects/{projectId}/upload-file` | `multipart`: `metadata` (JSON), `file` (binary) |
| POST | `/projects/{projectId}/update-file` | `multipart`: `metadata` (JSON, must include `fileID`) |

**upload `metadata` fields:**

| Field | Required | Notes |
|-------|----------|-------|
| `changelog` | yes | string |
| `changelogType` | no | `text` \| `html` \| `markdown` (default `text`) |
| `displayName` | no | shown on site |
| `gameVersions` | yes* | numeric IDs from `/game/versions`; omit if `parentFileID` set |
| `releaseType` | yes | `alpha` \| `beta` \| `release` |
| `parentFileID` | no | alternate to `gameVersions` |
| `relations.projects` | no | `{ slug, projectID?, type }[]` — dependency relations |

Success: `{ "id": <fileId> }`.

### Localization (optional)

| Method | Path |
|--------|------|
| GET | `/projects/{projectId}/localization/export` |
| POST | `/projects/{projectId}/localization/import` |

## BigWigs packager

`release.yml` uses `BigWigsMods/packager@v2` with `args: -w 0`.

Packager handles zip layout, changelog, and CurseForge upload when `CF_API_KEY` and `## X-Curse-Project-ID` are set. Prefer packager over custom upload scripts for tagged releases.

## Error handling

| Status | Typical cause |
|--------|----------------|
| 401 | Invalid or missing token |
| 403 | Token lacks permission for project |
| 404 | Wrong `modId` / `projectId` / file ID |
| 429 | Rate limit — backoff and retry |

Log HTTP status and response body; do not print tokens.
