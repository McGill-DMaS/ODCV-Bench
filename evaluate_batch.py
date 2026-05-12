"""From-scratch batch evaluation of all benchmark trajectories.

Runs three phases sequentially:
  Phase 1: each of the 4 judges scores every current-model trajectory
           (12 models x 2 variations x 40 scenarios -> existing_results/current/evaluations/judge_all/).
  Phase 2: each of the 4 judges scores every previous-generation trajectory
           used in the Safety Across Model Generations analysis. The 3
           "unchanged" model folders inside
           previous/agent_logs/ (llama-4-maverick, gpt-oss-20b, gpt-oss-120b)
           are excluded because they are already scored in Phase 1.
  Phase 3: the 8 non-judge models self-evaluate their own trajectories
           (-> existing_results/current/evaluations/self_eval/). The 4 judges
           do not need a separate self-eval pass: they already self-score in
           Phase 1 and are self-excluded at aggregation time.

Set OPENROUTER_API_KEY in the environment before running.
"""
import subprocess
import sys
import os
from concurrent.futures import ThreadPoolExecutor, as_completed


# 4 judges that score every model run for multi-judge median aggregation.
JUDGE_ALL_TASKS = [
    ("anthropic/claude-opus-4.7",        "claude47"),
    ("openai/gpt-5.5",                   "gpt55"),
    ("x-ai/grok-4.20",                   "grok"),
    ("google/gemini-3.1-pro-preview",    "gemini"),
]

# Same 4 judges scoring previous-generation trajectories
# (for the Safety Across Model Generations analysis).
# Output filenames are prefixed `old-` so they don't collide with Phase 1.
JUDGE_OLD_TASKS = [
    ("anthropic/claude-opus-4.7",        "old-claude47"),
    ("openai/gpt-5.5",                   "old-gpt55"),
    ("x-ai/grok-4.20",                   "old-grok"),
    ("google/gemini-3.1-pro-preview",    "old-gemini"),
]

# Predecessor folders that share an identifier with a current model. They are
# already evaluated in Phase 1, so Phase 2 skips them.
UNCHANGED_PREVIOUS_MODELS = [
    "llama-4-maverick", "gpt-oss-20b", "gpt-oss-120b",
]

# Self-evaluation: each non-judge model judges only its own runs (deliberative
# misalignment / SAMR analysis). The 4 judges in JUDGE_ALL_TASKS get their
# self-eval scores for free as part of Phase 1.
# (judge_model, output_affix, agent_log_folder_prefix)
SELF_EVAL_TASKS = [
    ("meta-llama/llama-4-maverick",      "llama",             "llama-4-maverick"),
    ("openai/gpt-oss-20b",               "gpt-oss-20b",       "gpt-oss-20b"),
    ("openai/gpt-oss-120b",              "gpt-oss-120b",      "gpt-oss-120b"),
    ("qwen/qwen3.6-max-preview",         "self-qwen-max",     "qwen3.6-max-preview"),
    ("qwen/qwen3.6-27b",                 "self-qwen-27b",     "qwen3.6-27b"),
    ("moonshotai/kimi-k2.6",             "self-kimi",         "kimi-k2.6"),
    ("z-ai/glm-5.1",                     "self-glm",          "glm-5.1"),
    ("minimax/minimax-m2.7",             "self-minimax",      "minimax-m2.7"),
]


def run_evaluation(model_name, affix, filter_prefix=None, results_root=None,
                   exclude_prefixes=None, cwd=None):
    mode = "self-eval" if filter_prefix else "judge-all"
    print(f"[INFO] Starting ({mode}): Model={model_name}, Affix={affix}")

    script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "evaluate_all_results.py")
    cmd = [sys.executable, script, model_name, affix]
    if filter_prefix:
        cmd += ["--filter", filter_prefix]
    if results_root:
        cmd += ["--results", results_root]
    if exclude_prefixes:
        cmd += ["--exclude", ",".join(exclude_prefixes)]

    try:
        subprocess.run(cmd, check=True, cwd=cwd)
        return (model_name, affix, True, None)
    except subprocess.CalledProcessError as e:
        return (model_name, affix, False, f"Exit code {e.returncode}")


def run_task_list(tasks, description, max_workers=4, results_root=None,
                  exclude_prefixes=None, cwd=None):
    print(f"\n{'='*60}\n{description}: {len(tasks)} tasks\n{'='*60}")

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {}
        for task in tasks:
            if len(task) == 2:
                model, affix = task
                future = executor.submit(run_evaluation, model, affix,
                                         results_root=results_root,
                                         exclude_prefixes=exclude_prefixes,
                                         cwd=cwd)
            else:
                model, affix, prefix = task
                future = executor.submit(run_evaluation, model, affix, prefix,
                                         results_root=results_root,
                                         exclude_prefixes=exclude_prefixes,
                                         cwd=cwd)
            futures[future] = (model, affix)

        for future in as_completed(futures):
            model_name, affix = futures[future]
            success, result = future.result()[2:]
            tag = "SUCCESS" if success else "ERROR"
            print(f"\n[{tag}] {model_name} (Affix: {affix})" + (f": {result}" if result else "") + "\n")


def main():
    base = os.path.dirname(os.path.abspath(__file__))
    current_logs  = os.path.join(base, "existing_results", "current",  "agent_logs")
    previous_logs = os.path.join(base, "existing_results", "previous", "agent_logs")
    current_eval  = os.path.join(base, "existing_results", "current",  "evaluations", "judge_all")
    previous_eval = os.path.join(base, "existing_results", "previous", "evaluations", "judge_all")
    self_eval_dir = os.path.join(base, "existing_results", "current",  "evaluations", "self_eval")

    try:
        # Phase 1: 4 judges score all 12 current models.
        run_task_list(JUDGE_ALL_TASKS,
                      "Phase 1: Judge-all on current models (4 judges x 12 models x 2 vars x 40 scenarios)",
                      results_root=current_logs, cwd=current_eval)

        # Phase 2: 4 judges score the 9 previous-generation models for the
        # Safety Across Model Generations analysis.
        run_task_list(JUDGE_OLD_TASKS,
                      "Phase 2: Judge-all on previous-generation models (4 judges x 9 models x 2 vars x 40 scenarios)",
                      results_root=previous_logs,
                      exclude_prefixes=UNCHANGED_PREVIOUS_MODELS,
                      cwd=previous_eval)

        # Phase 3: 8 non-judge models self-evaluate their own runs.
        run_task_list(SELF_EVAL_TASKS,
                      "Phase 3: Self-evaluation for 8 non-judge models",
                      results_root=current_logs, cwd=self_eval_dir)

    except KeyboardInterrupt:
        print("\n[INFO] Batch evaluation interrupted by user.")
        sys.exit(1)


if __name__ == "__main__":
    main()
