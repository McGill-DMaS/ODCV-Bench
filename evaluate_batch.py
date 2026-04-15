import subprocess
import sys
import os
from concurrent.futures import ThreadPoolExecutor, as_completed

# Judges that evaluate ALL model runs (for multi-judge averaging)
JUDGE_ALL_TASKS = [
    ("openai/gpt-5.4", "gpt54"),
    ("x-ai/grok-4.20", "grok"),
    ("anthropic/claude-opus-4.6", "claude"),
    ("google/gemini-3.1-pro-preview", "gemini"),
]

# Self-evaluation tasks: each model judges only its own runs (for deliberative misalignment)
# Only 5 non-judge new models need fresh self-eval.
# The 4 judges already judge all runs including their own.
# The 3 unchanged models (llama, gpt-oss-20b, gpt-oss-120b) also need self-eval re-run
# with updated rubric.
# (judge_model, affix, result_folder_prefix)
SELF_EVAL_TASKS = [
    ("qwen/qwen3.5-35b-a3b", "self-qwen-35b", "qwen3.5-35b-a3b"),
    ("minimax/minimax-m2.7", "self-minimax", "minimax-m2.7"),
    ("z-ai/glm-5.1", "self-glm", "glm-5.1"),
    ("moonshotai/kimi-k2.5", "self-kimi", "kimi-k2.5"),
    ("qwen/qwen3.5-plus-02-15", "self-qwen-plus", "qwen3.5-plus-02-15"),
    ("meta-llama/llama-4-maverick", "llama", "llama-4-maverick"),
    ("openai/gpt-oss-20b", "gpt-oss-20b", "gpt-oss-20b"),
    ("openai/gpt-oss-120b", "gpt-oss-120b", "gpt-oss-120b"),
]

# Judge-all tasks for previous (old) model runs — same 4 judges, different results dir
JUDGE_OLD_TASKS = [
    ("openai/gpt-5.4", "old-gpt54"),
    ("x-ai/grok-4.20", "old-grok"),
    ("anthropic/claude-opus-4.6", "old-claude"),
    ("google/gemini-3.1-pro-preview", "old-gemini"),
]

# Models unchanged between old and new — skip in Phase 2 (already judged in Phase 1)
UNCHANGED_MODELS = ["llama-4-maverick", "gpt-oss-20b", "gpt-oss-120b"]


def run_evaluation(model_name, affix, filter_prefix=None, results_root=None,
                    exclude_prefixes=None, cwd=None):
    """
    Runs a single evaluation task.
    """
    mode = "self-eval" if filter_prefix else "judge-all"
    print(f"[INFO] Starting ({mode}): Model={model_name}, Affix={affix}")

    script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "evaluate_all_results.py")
    cmd = [
        sys.executable,
        script,
        model_name,
        affix,
    ]
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
    except Exception as e:
        return (model_name, affix, False, str(e))


def run_task_list(tasks, description, max_workers=4, results_root=None,
                  exclude_prefixes=None, cwd=None):
    """Run a list of evaluation tasks in parallel."""
    print(f"\n{'='*60}")
    print(f"{description}: {len(tasks)} tasks")
    print(f"{'='*60}")

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
            if success:
                print(f"\n[SUCCESS] {model_name} (Affix: {affix})\n")
            else:
                print(f"\n[ERROR] {model_name} (Affix: {affix}): {result}\n")


def main():
    base = os.path.dirname(os.path.abspath(__file__))
    current_logs = os.path.join(base, "existing_results", "current", "agent_logs")
    previous_logs = os.path.join(base, "existing_results", "previous", "agent_logs")
    current_eval = os.path.join(base, "existing_results", "current", "evaluations", "judge_all")
    previous_eval = os.path.join(base, "existing_results", "previous", "evaluations", "judge_all")
    self_eval_dir = os.path.join(base, "existing_results", "current", "evaluations", "self_eval")

    try:
        # Phase 1: 4 judges score all 12 current models
        run_task_list(JUDGE_ALL_TASKS,
                      "Phase 1: Judge-all on current models (12 models x 2 vars x 40 scenarios x 4 judges)",
                      results_root=current_logs, cwd=current_eval)

        # Phase 2: 4 judges score 9 previous models (exclude 3 unchanged — already in Phase 1)
        run_task_list(JUDGE_OLD_TASKS,
                      "Phase 2: Judge-all on previous models (9 old models x 2 vars x 40 scenarios x 4 judges)",
                      results_root=previous_logs, exclude_prefixes=UNCHANGED_MODELS,
                      cwd=previous_eval)

        # Phase 3: Self-evaluation for 8 non-judge models
        run_task_list(SELF_EVAL_TASKS,
                      "Phase 3: Self-evaluation for 8 non-judge models",
                      results_root=current_logs, cwd=self_eval_dir)

    except KeyboardInterrupt:
        print("\n[INFO] Batch evaluation interrupted by user.")
        sys.exit(1)


if __name__ == "__main__":
    main()
