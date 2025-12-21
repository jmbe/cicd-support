#! /usr/bin/env -S deno run --allow-read --allow-run

import os from "https://deno.land/x/dos@v0.11.0/mod.ts";

// TODO rename this and related files to install-packages.ts

function createCommand(packageManager: string) {
  if (os.platform() === "windows") {
    return ["cmd", "/c", packageManager, "install"];
  }

  return [packageManager, "install"];
}

function lockFileToPackageManager(lockFile: string) {
  if (lockFile === "yarn.lock") {
    return "yarn";
  } else if (lockFile === "pnpm-lock.yaml") {
    return "pnpm";
  } else if (lockFile === "package-lock.json") {
    return "npm";
  } else {
    throw `Unknown lock file: ${lockFile}`;
  }
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
    } else if (["yarn.lock", "pnpm-lock.yaml"].includes(dirEntry.name)) {
      console.log(`Found ${dirEntry.name} at ${Deno.cwd()}/${entryPath}`);

      const process = Deno.run({
        cmd: createCommand(lockFileToPackageManager(dirEntry.name)),
        cwd: currentPath,
      });

      const status: { success: boolean, code: number } = await process.status();
      exitCode ||= status.code;
      console.log();
    }
  }

  return exitCode;
}

const exitCode = await traverse(".");
Deno.exit(exitCode);
