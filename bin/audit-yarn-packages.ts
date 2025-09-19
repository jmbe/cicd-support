#! /usr/bin/env -S npx --yes deno@latest run --allow-read --allow-run

import os from "https://deno.land/x/dos@v0.11.0/mod.ts";

const yarnArgs = [
  "npm",
  "audit",
  "--environment",
  "production",
  "--severity",
  "moderate",
  /* List of vulnerabilities to ignore - repeat --ignore to ignore different vulnerabilities */
  // Bootstrap 4.x affects unused carousel component https://github.com/advisories/GHSA-vc8w-jr9v-vj7f
  "--ignore", "1103908",
];

function createCommand() {
  if (os.platform() === "windows") {
    return ["cmd", "/c", "yarn", ...yarnArgs];
  }

  return ["yarn", ...yarnArgs];
}

const ignoredDirectories = [
  ".git",
  "cache",
  "node",
  "node_modules",
  "target",
];

async function traverse(currentPath: string, exitCode: number = 0): Promise<number> {

  for await (const dirEntry of Deno.readDir(currentPath)) {
    const entryPath = `${currentPath}/${dirEntry.name}`;

    // console.log(`Traversing ${entryPath}...`);

    if (dirEntry.isDirectory) {
      if (!ignoredDirectories.includes(dirEntry.name)) {
        const code = await traverse(entryPath, exitCode);
        exitCode ||= code;
      }
    } else if ("yarn.lock" === dirEntry.name) {
      console.log(`Found yarn.lock at ${Deno.cwd()}/${entryPath}`);

      const process = Deno.run({
        cmd: createCommand(),
        cwd: currentPath,
      });

      const status = await process.status();
      exitCode ||= status.code;
    }
  }

  return exitCode;
}

const exitCode = await traverse(".");
Deno.exit(exitCode);
