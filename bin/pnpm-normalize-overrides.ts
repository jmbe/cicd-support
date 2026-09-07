#! /usr/bin/env -S npx --yes deno run --allow-read --allow-write

// Pipeline:
// Read overrides from pnpm-workspace.yaml
// Normalize every entry to: {package}@<{version}: '<constraint>'
//    - where constraint is usually "^<version>", ">=<version>" or "<version>"
// Sort normalized entries by package name and version
// Deduplicate by package name keeping the highest version
// Produce new pnpm-workspace.yaml
// Final formatting: add a blank line between each top-level key
//
// Note: YAML is re-serialized; comments/formatting may change.

import * as semver from "jsr:@std/semver@1.0.0";
import {parse as parseYaml, stringify as stringifyYaml} from "jsr:@std/yaml@1.0.9";

// Packages in this list are allowed to remain at its old version and should therefore NOT be overridden.
// These packages will be removed from the pnpm overrides list, which is necessary since pnpm audit --fix will insist
// on adding them, even though they have been added to ignoreGhsas.
const ignoredPackages = [
  // ajv cannot be upgraded yet due to eslint requires 6.x https://github.com/eslint/eslint/issues/20508#issuecomment-3919981356
  "ajv",
];

type OverrideEntry = {
  packageName: string;
  version: string;
  key: string;
  value: string;
};

function basePackageName(rawKey: string): string {
  const at = rawKey.lastIndexOf("@");
  return at > 0 ? rawKey.slice(0, at) : rawKey;
}

/**
 * Parses the target version to extract the mentioned version for use in the overrides' key name,
 * such as "^1.2.3" → {targetVersion "1.2.3", targetVersionExpression "^1.2.3"}.
 */
function parseOverrideValue(rawValue: string): {
  // The actual target version, to be used in the override key name
  targetVersion: string;
  /*
    The target version expression, to be used in the override value.
    The expression may contain range selectors such as "~" or "^".
   */
  targetVersionExpression: string
} {
  const trimmed = rawValue.trim();

  let match = trimmed.match(/^(\^|~|>=)\s*([0-9A-Za-z.+-]+)\s*$/);
  if (match) {
    const rangeOperator = match[1]!;
    const version = match[2]!;
    return {targetVersion: version, targetVersionExpression: `${rangeOperator}${version}`};
  }

  // "1.2.3" (exact version, keep as-is)
  match = trimmed.match(/^([0-9A-Za-z.+-]+)\s*$/);
  if (match) {
    const version = match[1]!;
    return {targetVersion: version, targetVersionExpression: version};
  }

  throw new Error(`Failed to match version, received: ${JSON.stringify(rawValue)}`);
}

/**
 * Insert blank lines lost during round-trip to match default pnpm formatting.
 */
function addBlankLinesBetweenTopLevelKeys(yamlText: string): string {
  const lines = yamlText.split(/\r?\n/);

  const out: string[] = [];
  let seenFirstTopLevelKey = false;

  for (const line of lines) {
    const trimmed = line.trim();
    const isDocumentMarker = trimmed === "---" || trimmed === "...";

    // Top-level mapping entry (no indentation).
    // Accept both:
    //   key:
    //   key: value
    // (but avoid list items like "- something" and comment-only lines)
    const isTopLevelKey =
      !isDocumentMarker &&
      line.length > 0 &&
      line[0] !== " " &&
      line[0] !== "\t" &&
      line[0] !== "-" &&
      line[0] !== "#" &&
      /^[^:#]+:\s*(?:.*)?$/.test(line);

    if (isTopLevelKey) {
      if (seenFirstTopLevelKey) {
        if (out.length > 0 && out[out.length - 1].trim() !== "") out.push("");
      }
      seenFirstTopLevelKey = true;
    }

    out.push(line);
  }

  return out.join("\n");
}

async function parseDocument(filePath: string): Promise<Record<string, unknown>> {
  const input = await Deno.readTextFile(filePath);
  const doc = parseYaml(input) as Record<string, unknown>;
  return doc;
}

function parseOverrides(yamlDocument: Record<string, unknown>): Record<string, string> {

  const overrides = yamlDocument["overrides"];
  if (!overrides || typeof overrides !== "object" || Array.isArray(overrides)) {
    throw new Error(`No 'overrides' mapping found in ${filePath}`);
  }

  return overrides as Record<string, string>;
}

/**
 Normalize all entries (skipping whitelisted packages)
 */
function normalizeOverrides(
  overrides: Record<string, string>,
  ignoredPackages: string[],
): OverrideEntry[] {
  const normalized: OverrideEntry[] = [];

  for (const [rawKey, rawValue] of Object.entries(overrides as Record<string, string>)) {
    const pkg = basePackageName(String(rawKey));

    // Remove any updates to whitelisted packages (e.g., "ajv")
    if (ignoredPackages.includes(pkg)) {
      continue;
    }

    const {targetVersion, targetVersionExpression} = parseOverrideValue(rawValue);

    normalized.push({
      packageName: pkg,
      version: targetVersion,
      key: `${pkg}@<${targetVersion}`,
      value: targetVersionExpression,
    });
  }

  return normalized;
}

/**
 * Compares by package name, then semver version, such that the last entry in the sorted list is the highest version.
 */
function compareOverrideEntries(a: OverrideEntry, b: OverrideEntry) {
  if (a.packageName !== b.packageName) {
    return a.packageName.localeCompare(b.packageName);
  }

  try {
    const semverA = semver.parse(a.version);
    const semverB = semver.parse(b.version);

    return semver.compare(semverA, semverB);
  } catch (e) {
    console.error("Failed to compare versions:", JSON.stringify(a.version), JSON.stringify(b.version));
    throw e;
  }
}

/**
 Deduplicate by package name keeping the highest version
 */
function deduplicatePackageNames(entries: OverrideEntry[]): Record<string, string> {
  const sortedEntries = entries.toSorted(compareOverrideEntries);

  const lastWriteIsHighestVersion = new Map<string, OverrideEntry>();
  for (const entry of sortedEntries) {
    lastWriteIsHighestVersion.set(entry.packageName, entry);
  }

  // Emit sorted again by package name, for use in overrides list
  const finalEntries = [...lastWriteIsHighestVersion.values()]
    .sort((a, b) =>
      a.packageName.localeCompare(b.packageName),
    );

  const canonical: Record<string, string> = {};
  for (const e of finalEntries) {
    canonical[e.key] = e.value;
  }
  return canonical;
}

const filePath = Deno.args[0] ?? "pnpm-workspace.yaml";
const yamlDocument = await parseDocument(filePath);
const currentOverrides = parseOverrides(yamlDocument);
const normalized = normalizeOverrides(currentOverrides, ignoredPackages);
const deduplicatedOverridesEntries = deduplicatePackageNames(normalized);

yamlDocument["overrides"] = deduplicatedOverridesEntries;

// Convert to yaml
const yamlOut = stringifyYaml(yamlDocument, {
  lineWidth: -1,
});

// Final formatting: add a blank line between each top-level key
const formattedYaml = addBlankLinesBetweenTopLevelKeys(yamlOut);
await Deno.writeTextFile(filePath, formattedYaml);
