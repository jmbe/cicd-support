@echo off

rem Trailing slash will not be removed
SET scriptdir=%~dp0

deno run --allow-read --allow-run %scriptdir%exec-for-package-matches.ts %*
