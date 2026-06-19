/// <reference types="bun" />

import { syncTocVersion } from "./sync-toc-version";

const root = `${import.meta.dir}/..`;

const changeset = Bun.spawn(["bunx", "changeset", "version"], {
  cwd: root,
  stdout: "inherit",
  stderr: "inherit",
  stdin: "ignore",
});

const exitCode = await changeset.exited;
if (exitCode !== 0) {
  process.exit(exitCode);
}

await syncTocVersion();
