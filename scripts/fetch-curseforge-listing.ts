/// <reference types="bun" />

const MOD_ID = 1584836;

function token(): string {
  const key = process.env.CF_API_KEY ?? process.env.CURSEFORGE_API_KEY;
  if (!key) {
    console.error("fetch-curseforge-listing: CF_API_KEY or CURSEFORGE_API_KEY required");
    process.exit(1);
  }
  return key;
}

async function cfFetch(path: string): Promise<unknown> {
  const res = await fetch(`https://api.curseforge.com/v1${path}`, {
    headers: { Accept: "application/json", "x-api-token": token() },
  });
  if (!res.ok) {
    console.error(`fetch-curseforge-listing: ${path} failed (${res.status})`);
    process.exit(1);
  }
  return res.json();
}

export async function fetchCurseForgeListing(): Promise<{ summary: string; description: string }> {
  const mod = (await cfFetch(`/mods/${MOD_ID}`)) as { data: { summary?: string; description?: string } };
  const desc = (await cfFetch(`/mods/${MOD_ID}/description`)) as { data?: string };
  return {
    summary: mod.data.summary ?? "",
    description: desc.data ?? mod.data.description ?? "",
  };
}

if (import.meta.main) {
  const listing = await fetchCurseForgeListing();
  console.log(JSON.stringify(listing, null, 2));
}
