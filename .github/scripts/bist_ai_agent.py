#!/usr/bin/env python3
"""Read-only AI diagnosis of recent Android CI runs; posts an issue for review."""
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request

repo = os.environ["GH_REPO"]
token = os.environ["GH_TOKEN"]
key = os.environ["OPENAI_API_KEY"]

def gh(path):
    req = urllib.request.Request(
        "https://api.github.com/repos/" + repo + path,
        headers={"Authorization": "Bearer " + token, "Accept": "application/vnd.github+json",
                 "User-Agent": "bist-viop-ai-agent"})
    with urllib.request.urlopen(req, timeout=25) as response:
        return json.load(response)

runs = gh("/actions/runs?per_page=15")["workflow_runs"]
failed = [r for r in runs if r.get("conclusion") == "failure" and
          r.get("name") != "BIST VIOP AI Agent (diagnostic)"][:3]
if not failed:
    print("No failed Android workflow runs found; nothing to diagnose.")
    sys.exit(0)

evidence = []
for run in failed:
    jobs = gh("/actions/runs/%s/jobs?per_page=30" % run["id"])["jobs"]
    evidence.append({
        "run_url": run["html_url"], "workflow": run["name"], "sha": run["head_sha"],
        "failed_steps": [{"job": job["name"], "step": step["name"]}
                         for job in jobs for step in job.get("steps", [])
                         if step.get("conclusion") == "failure"]
    })

prompt = (
    "You are a cautious Android CI diagnostic assistant. In Turkish, summarize the "
    "observed failures, suggest specific investigation and fixes. Do not claim any "
    "fix was applied or tests passed. Use only the supplied evidence. "
    "Do not output credentials. Keep under 1200 words. Evidence: " +
    json.dumps(evidence, ensure_ascii=False)
)
body = json.dumps({"model": "gpt-4.1-mini", "input": prompt}).encode("utf-8")
req = urllib.request.Request(
    "https://api.openai.com/v1/responses", data=body, method="POST",
    headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"})
try:
    with urllib.request.urlopen(req, timeout=90) as response:
        result = json.load(response)
except urllib.error.HTTPError as exc:
    print("OpenAI request failed with HTTP status", exc.code, file=sys.stderr)
    sys.exit(1)

parts = [part.get("text", "") for output in result.get("output", [])
         for part in output.get("content", []) if part.get("type") == "output_text"]
analysis = "\n".join(parts).strip()
if not analysis:
    raise RuntimeError("OpenAI returned no diagnostic text")

title = "AI diagnostic: Android CI failures"
issue_body = ("Automated diagnostic only; no code changes or APK verification.\n\n" +
              analysis[:50000] + "\n\nEvidence:\n" +
              "\n".join("- " + item["run_url"] for item in evidence))
existing = gh("/issues?state=open&per_page=100")
if any(i.get("title") == title and "pull_request" not in i for i in existing):
    print("Diagnostic issue already open; avoiding duplicate.")
    print(analysis[:1500])
    sys.exit(0)
payload = json.dumps({"title": title, "body": issue_body}).encode("utf-8")
request = urllib.request.Request(
    "https://api.github.com/repos/" + repo + "/issues", data=payload, method="POST",
    headers={"Authorization": "Bearer " + token, "Accept": "application/vnd.github+json",
             "Content-Type": "application/json", "User-Agent": "bist-viop-ai-agent"})
with urllib.request.urlopen(request, timeout=25) as response:
    issue = json.load(response)
print("Created diagnostic issue:", issue["html_url"])
