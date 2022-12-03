#! /usr/bin/env -S deno run --allow-read --allow-run

import os from "https://deno.land/x/dos@v0.11.0/mod.ts";

if (!Deno.args[1]) {
  console.log("Usage: exec-for-package-matches.ts package command-to-execute...");
  console.log();
  console.log("Examples:");
  console.log();
  console.log("  exec-for-package-matches.ts @angular/cli yarn run ng update @angular/cli --allow-dirty");
  // Note that matching package @angular/cli is intended in the next sample, to support running ng
  console.log("  exec-for-package-matches.ts @angular/cli \"yarn && yarn run ng update @angular/core --allow-dirty --force\"");
  // Sample for major Angular upgrades, e.g. 9 -> 10
  console.log("  exec-for-package-matches.ts @angular/cli \"yarn && yarn run ng update @angular/core @angular/cli --allow-dirty --force\"");
  // Take care to quote properly when the command line to run uses pipes
  console.log("  exec-for-package-matches.ts @angular-devkit/build-angular \"cat package.json | jq '.resolutions.typescript = \\\"3.8.3\\\"' | sponge package.json && yarn\"");
  // Sample selective resolution, keyname must be quoted
  console.log("  exec-for-package-matches.ts @angular-devkit/build-angular \"cat package.json | jq '.resolutions.\\\"@angular-devkit/**/typescript\\\" = \\\"3.8.3\\\"' | sponge package.json && yarn\"");
  console.log("  exec-for-package-matches.ts eslint \"pwd && yarn && yarn run eslint --fix\"");
  console.log();

  Deno.exit(1);
}


const matchPackage = Deno.args[0];
const exec = [...Deno.args];
exec.shift();


function createCommand() {
  if (os.platform() === "windows") {
    return ["cmd", "/c", ...exec];
  }

  return ["bash", "-c", ...exec];
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
    } else if ("package.json" === dirEntry.name) {
      const text = await Deno.readTextFile(entryPath);

      if (text.includes(matchPackage)) {
        console.log(`Found matching package.json at ${Deno.cwd()}/${entryPath}`);

        const process = Deno.run({
          cmd: createCommand(),
          cwd: currentPath,
        });

        await process.status();
        console.log();
      }
    }
  }
}

await traverse(".");
