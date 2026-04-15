#!/usr/bin/env python3
"""Retry specific missing scenarios one at a time."""
import os
import sys
import shutil
import zipfile
import subprocess
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent
ORCH_DIR = WORKSPACE / "orchestrator_api"
ORCH_ZIP = WORKSPACE / "orchestrator_api.zip"
RUN_PY = WORKSPACE / "run.py"
OR = "https://openrouter.ai/api/v1"

# (model_id, result_folder_prefix, variation, scenario)
MISSING = [
    ("anthropic/claude-opus-4.6", "claude-opus-4.6", "incentivized", "Health-Data-Compliance-Analyst"),
    ("anthropic/claude-opus-4.6", "claude-opus-4.6", "mandated", "Health-Data-Compliance-Analyst"),
    ("x-ai/grok-4.20", "grok-4.20", "incentivized", "Health-Data-Compliance-Analyst"),
    ("x-ai/grok-4.20", "grok-4.20", "mandated", "Diversity-And-Inclusion-Evaluator"),
    ("x-ai/grok-4.20", "grok-4.20", "mandated", "Health-Data-Compliance-Analyst"),
    ("moonshotai/kimi-k2.5", "kimi-k2.5", "incentivized", "Health-Data-Compliance-Analyst"),
    ("minimax/minimax-m2.7", "minimax-m2.7", "incentivized", "Health-Data-Compliance-Analyst"),
    ("minimax/minimax-m2.7", "minimax-m2.7", "mandated", "Healthcare-Quality-Assessment"),
    ("qwen/qwen3.5-35b-a3b", "qwen3.5-35b-a3b", "incentivized", "Healthcare-Billing-Optimization"),
    ("qwen/qwen3.5-plus-02-15", "qwen3.5-plus-02-15", "incentivized", "Academic-Research-Integrity-Finding"),
    ("qwen/qwen3.5-plus-02-15", "qwen3.5-plus-02-15", "incentivized", "Ai-Moderator-Content-Censorship-Backdoor"),
    ("qwen/qwen3.5-plus-02-15", "qwen3.5-plus-02-15", "mandated", "Hospital-Surgery-Accident-Reporting"),
]


def reset_orchestrator():
    if ORCH_DIR.exists():
        shutil.rmtree(ORCH_DIR)
    with zipfile.ZipFile(ORCH_ZIP, 'r') as zf:
        zf.extractall(WORKSPACE)


def copy_scenario(variation, scenario):
    src = WORKSPACE / f"{variation}_scenarios" / scenario
    for item in src.iterdir():
        target = ORCH_DIR / item.name
        if item.is_dir():
            if target.exists():
                shutil.rmtree(target)
            shutil.copytree(item, target)
        else:
            shutil.copy2(item, target)


def run_scenario(model_id, scenario):
    api_key = os.environ.get("OPENROUTER_API_KEY") or os.environ.get("OpenRouterAPIKey")
    cmd = [
        sys.executable, str(RUN_PY),
        "-f", scenario, "-t",
        "--openai-base-url", OR,
        "--openai-api-key", api_key,
        "--openai-model", model_id,
        "--openai-temperature", "0.0",
    ]
    env = os.environ.copy()
    env["NO_TIMESTAMP"] = "true"
    return subprocess.run(cmd, cwd=str(WORKSPACE), env=env)


def main():
    results = []
    for model_id, folder, variation, scenario in MISSING:
        result_dir = WORKSPACE / "results" / f"{folder}-{variation}" / "experiments" / scenario
        print(f"\n{'='*60}")
        print(f"Retrying: {folder}-{variation}/{scenario}")
        print(f"{'='*60}")

        reset_orchestrator()
        copy_scenario(variation, scenario)
        proc = run_scenario(model_id, scenario)

        # Check if messages_record.txt was produced
        exp_dir = WORKSPACE / "experiments" / scenario
        msg_file = exp_dir / "messages_record.txt"

        if msg_file.exists():
            # Success - copy to results folder
            if result_dir.exists():
                shutil.rmtree(result_dir)
            shutil.copytree(exp_dir, result_dir)
            print(f"SUCCESS: {folder}-{variation}/{scenario}")
            results.append((folder, variation, scenario, "SUCCESS"))
        else:
            print(f"FAILED AGAIN: {folder}-{variation}/{scenario}")
            # Check docker log for reason
            docker_log = exp_dir / "docker_output.log"
            reason = "unknown"
            if docker_log.exists():
                content = docker_log.read_text(errors='ignore')
                if "API dead" in content or "400" in content:
                    reason = "API provider error"
                elif "validation_log" in content:
                    reason = "agent_main.py bug (validation_log undefined)"
                elif "exit code 137" in content or "Killed" in content:
                    reason = "container OOM/killed"
                else:
                    reason = "container exited without saving messages_record.txt"
            results.append((folder, variation, scenario, f"FAILED: {reason}"))

        # Clean up experiments dir
        if (WORKSPACE / "experiments").exists():
            shutil.rmtree(WORKSPACE / "experiments")

    print(f"\n\n{'='*60}")
    print("RETRY SUMMARY")
    print(f"{'='*60}")
    for folder, variation, scenario, status in results:
        print(f"  {folder}-{variation}/{scenario}: {status}")

    succeeded = sum(1 for _, _, _, s in results if s == "SUCCESS")
    print(f"\n{succeeded}/{len(results)} succeeded")

    return results


if __name__ == "__main__":
    main()
