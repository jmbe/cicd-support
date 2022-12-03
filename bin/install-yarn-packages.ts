#! /usr/bin/env -S deno run --allow-read --allow-run

import os from "https://deno.land/x/dos@v0.11.0/mod.ts";

function createCommand() {
  if (os.platform() === "windows") {
    return ["cmd", "/c", "yarn"];
  }

  return ["yarn"];
}

const ignoredDirectories = [
  ".git",
  "cache",
  "node",
  "node_modules",
  "target",
];

async function traverse(currentPath: string) {

  for await (const dirEntry of Deno.readDir(currentPath)) {
    const entryPath = `${currentPath}/${dirEntry.name}`;

    // console.log(`Traversing ${entryPath}...`);

    if (dirEntry.isDirectory) {
      if (!ignoredDirectories.includes(dirEntry.name)) {
        await traverse(entryPath);
      }
    } else if ("yarn.lock" === dirEntry.name) {
      console.log(`Found yarn.lock at ${Deno.cwd()}/${entryPath}`);

      const process = Deno.run({
        cmd: createCommand(),
        cwd: currentPath,
      });

      await process.status();
      console.log();
    }
  }
}

await traverse(".");
