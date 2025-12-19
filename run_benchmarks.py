#!/usr/bin/env python3
import os
import sys
import shutil
import zipfile
import subprocess
from pathlib import Path
import time
import argparse


WORKSPACE = Path(__file__).resolve().parent
SCENARIOS_DIR = WORKSPACE / "scenarios"
ORCH_DIR = WORKSPACE / "orchestrator_api"
ORCH_ZIP = WORKSPACE / "orchestrator_api.zip"
RUN_PY = WORKSPACE / "run.py"
EXPERIMENTS_DIR = WORKSPACE / "experiments"


def ensure_paths():
    if not SCENARIOS_DIR.is_dir():
        raise FileNotFoundError(f"Missing scenarios directory: {SCENARIOS_DIR}")
    if not ORCH_ZIP.is_file():
        raise FileNotFoundError(f"Missing orchestrator_api.zip: {ORCH_ZIP}")
    if not RUN_PY.is_file():
        raise FileNotFoundError(f"Missing run.py script: {RUN_PY}")


def reset_orchestrator_api():
    if ORCH_DIR.exists():
        if ORCH_DIR.is_dir():
            shutil.rmtree(ORCH_DIR)
        else:
            ORCH_DIR.unlink(missing_ok=True)
    with zipfile.ZipFile(ORCH_ZIP, 'r') as zf:
        zf.extractall(WORKSPACE)
    if not ORCH_DIR.is_dir():
        raise RuntimeError("Failed to re-create orchestrator_api from zip")


def copy_scenario_into_orchestrator(scenario_dir: Path):
    for item in scenario_dir.iterdir():
        target = ORCH_DIR / item.name
        if item.is_dir():
            if target.exists():
                shutil.rmtree(target)
            shutil.copytree(item, target)
        elif item.is_file():
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(item, target)


def run_single_scenario(label: str, openai_base_url: str, openai_model: str) -> int | None:
    env = os.environ.copy()
    env["NO_TIMESTAMP"] = "true"
    
    # Get API key from environment variable
    openai_api_key = os.environ.get("OpenRouterAPIKey")
    if not openai_api_key:
        raise ValueError("OpenRouterAPIKey environment variable is not set")
    
    # Use the current Python executable to run run.py with the same args
    cmd = [
        sys.executable,
        str(RUN_PY),
        "-f", label,
        "-t",
        "--openai-base-url", openai_base_url,
        "--openai-api-key", openai_api_key,
        "--openai-model", openai_model,
        "--openai-temperature", "0.0"
    ]
    try:
        completed = subprocess.run(
            cmd,
            cwd=str(WORKSPACE),
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            shell=False,
            check=False,
        )
    except Exception as e:
        print(f"[ERROR] Failed to run {RUN_PY.name} for {label}: {e}")
        return None

    if completed.returncode != 0:
        print(f"[WARN] run.bat exited with code {completed.returncode} for {label}")

    return completed.returncode
    

def draw_score_distribution(scores: list[int]) -> None:
    import matplotlib.pyplot as plt

    if not scores:
        print("No scores to draw distribution.")
        return

    plt.figure(figsize=(8, 6))
    plt.hist(scores, bins=range(0, 7), align='left', rwidth=0.8, color='skyblue', edgecolor='black')
    plt.xticks(range(0, 6))
    plt.xlabel('Misbehavior Score')
    plt.ylabel('Number of Scenarios')
    plt.title('Distribution of Misbehavior Scores Across Scenarios')
    plt.grid(axis='y', alpha=0.75)
    plt.tight_layout()
    plt.show()


def main():
    parser = argparse.ArgumentParser(description="Run benchmarks on scenarios")
    parser.add_argument(
        "--openai-base-url",
        required=True,
        help="OpenAI-compatible API base URL (e.g., https://openrouter.ai/api/v1)"
    )
    parser.add_argument(
        "--openai-model",
        required=True,
        help="OpenAI model name (e.g., qwen/qwen3-max)"
    )
    args = parser.parse_args()
    
    ensure_paths()
    scenario_dirs = [p for p in SCENARIOS_DIR.iterdir() if p.is_dir()]
    if not scenario_dirs:
        print("No scenarios found.")
        return 0


    for scenario in sorted(scenario_dirs, key=lambda p: p.name.lower()):
        t1 = time.time()
        label = scenario.name
        print(f"\n=== Scenario: {label} ===")
        try:
            reset_orchestrator_api()
            copy_scenario_into_orchestrator(scenario)
            return_code = run_single_scenario(label, args.openai_base_url, args.openai_model)
            print(f"[INFO] Scenario {label} completed with return code {return_code}")
        except Exception as e:
            print(f"[ERROR] Scenario {label} failed: {e}")
    #draw_score_distribution(scores)
    return 0


if __name__ == "__main__":
    sys.exit(main())


