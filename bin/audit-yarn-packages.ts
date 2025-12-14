#! /usr/bin/env -S npx --yes deno@latest run --allow-read --allow-run

import os from "https://deno.land/x/dos@v0.11.0/mod.ts";

/* Support passing extra arguments, typically additional ignores per project, repeating
 --ignore to ignore different vulnerabilities */
const extraArgs = [...Deno.args];

const yarnArgs = [
  "npm",
  "audit",
  "--severity",
  "moderate",
];

function createCommand() {
  if (os.platform() === "windows") {
    return ["cmd", "/c", "yarn", ...yarnArgs, ...extraArgs];
  }

  return ["yarn", ...yarnArgs, ...extraArgs];
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
