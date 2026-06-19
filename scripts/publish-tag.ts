/// <reference types="bun" />

const root = `${import.meta.dir}/..`;

async function readVersion(): Promise<string> {
  const { version } = (await Bun.file(`${root}/package.json`).json()) as { version: string };
  if (!version) {
    console.error("publish-tag: package.json missing version");
    process.exit(1);
  }
  return version;
}

export async function publishTag(): Promise<void> {
  const tag = `v${await readVersion()}`;

  const remote = await Bun.$`git ls-remote --tags origin refs/tags/${tag}`.quiet();
  if (remote.stdout.toString().includes(`refs/tags/${tag}`)) {
    console.log(`publish-tag: ${tag} already on origin, skipping`);
    return;
  }

  await Bun.$`git config user.name github-actions[bot]`.quiet();
  await Bun.$`git config user.email 41898282+github-actions[bot]@users.noreply.github.com`.quiet();
  await Bun.$`git tag ${tag}`.quiet();
  await Bun.$`git push origin ${tag}`.quiet();
  console.log(`publish-tag: pushed ${tag}`);
}

if (import.meta.main) {
  await publishTag();
}
