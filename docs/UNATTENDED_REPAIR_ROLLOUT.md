# Unattended Build 668 repair rollout (not yet active)

Scope: a failed diagnostic CI run may generate a candidate fix in a separate `automation/fix-<run-id>` branch and draft PR. Never modify or merge main without explicit human approval.

## Verified repository workflows
- `Build Android APK (Build 668)` — `.github/workflows/android-apk-build.yml`
- `BIST VIOP Build 668 APK` — `.github/workflows/build-668-from-zip.yml`

Update the intake `workflow_run.workflows` names to the exact strings above before enabling. The intake workflow only triggers from the default branch.

## Required before activation
1. Configure `OPENAI_API_KEY` as a GitHub Actions secret through the GitHub UI. Never commit it to the repository.
2. Implement a least-privilege follow-up workflow using `openai/codex-action@v1` on a failed trusted CI run. Run all dependency setup before the Codex job, without passing API credentials to tests. Pin action versions and check branch/event trust boundaries.
3. Codex job must have `contents: read`, produce a patch artifact, and have no ability to push to main. In a separate restricted job, validate allowed paths, apply patch in a dedicated branch, run diagnostic unit tests/lint/assembleDiagnostic, then open a draft PR if tests pass. Prevent recursion and limit retries.
4. For BUILD 668, validate S/D toggle on/off, lifecycle and timeframe changes, RSI/Bollinger regression, financial formulas with reference fixtures, BIST delayed mode separately from live VIOP provider, and visual checks when an emulator is available. A successful build alone does not prove correctness.
5. Demonstrate one deliberate test failure and resulting diagnostic PR before enabling unattended fixing. Human approval remains required to merge.

Status: design and checklist only; **agent is not active**. This document does not authorize additional repository permissions, secret management, or automatic merges.

References: https://github.com/openai/codex-action and https://learn.chatgpt.com/docs/non-interactive-mode
