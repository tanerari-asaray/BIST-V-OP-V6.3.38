# Automatic repair agent activation checklist

Status: NOT ACTIVE. The failure-intake workflow can only open issues once merged into the default branch and once its configured workflow names match existing CI workflow names.

1. Identify the exact Android build workflow display name and adjust `.github/workflows/diagnostic-failure-intake.yml` accordingly.
2. Confirm the Android source is checked out, wrapper is executable, and Gradle SDK setup works.
3. Configure an approved coding agent/provider with its own credential and least-privilege GitHub access. Never embed a credential in repository files or logs.
4. On failure: inspect job logs -> isolate the root cause -> create `automation/fix-<run-id>` branch -> make a minimal patch -> run test/lint/assembleDiagnostic -> open a PR with evidence and any APK artifact.
5. No automatic changes to the default branch. Review and explicit approval are mandatory before merge.
6. Limit retries and avoid loops caused by agent-created PR workflows.

The issue intake workflow does not access an AI model and cannot repair code by itself. Keep PR as draft until trigger names and security review are complete.
