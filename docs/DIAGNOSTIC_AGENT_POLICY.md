# BIST–VİOP BUILD 668 — Controlled Diagnostic Agent Policy

## Purpose
Detect CI failures, collect useful logs, propose narrow fixes, and verify Android diagnostic builds without altering main automatically.

## Allowed
- Analyze failed GitHub Actions logs and Gradle test reports.
- Edit only a dedicated `automation/fix-*` branch.
- Re-run tests and `assembleDiagnostic` where the Android project supports that task.
- Create a pull request documenting root cause, changes, test evidence, and downloadable artifacts.

## Prohibited by default
- No direct commits or auto-merges to `main`.
- Do not modify signing credentials, release keys, secrets, workflow permissions, or external integrations without explicit authorization.
- No force push and no destructive repository operations.
- Never claim a build passed unless the workflow confirms success.
- Never assert on-device rendering, live VİOP feeds, or S/D toggle behavior without corresponding tests.

## Required gates
1. Repository source tree and Gradle wrapper validated.
2. Dependency setup and Android SDK toolchain verified.
3. Unit tests, lint, and diagnostic assemble executed when configured.
4. Artifacts and logs retained; failure summaries include exact error location.
5. Human review required before merging.

## Build 668 acceptance focus
- RSI and Bollinger controls remain unchanged.
- S/D control matches current indicator button size, spacing, and colors.
- Turning S/D off hides all support/resistance lines; on reveals only applicable levels.
- Verify chart lifecycle, symbol switching, timeframe transitions, accessibility, and screen overflow.
- Treat delayed BIST mode separately from live VİOP provider configuration.

## Status
Configuration policy only. This file does not itself install an AI agent, grant permissions, trigger workflows, or start a continuous repair service.
