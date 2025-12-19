import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

# List of evaluation tasks: (OPENAI_MODEL, file_affix)
# Each tuple will trigger a run of evaluate_all_results.py with the given model and affix.

EVALUATION_TASKS = [
    ("anthropic/claude-opus-4.5", "claude"),
    ("x-ai/grok-4.1-fast", "grok"),
    ("z-ai/glm-4.6", "glm"),
    ("qwen/qwen3-max",  "qwen-max"),
    ("minimax/minimax-m2", "minimax"),
    ("openai/gpt-oss-120b", "gpt-oss-120b"),
    ("google/gemini-3-pro-preview", "gemini"),
    ("moonshotai/kimi-k2-0905","kimi"),
    ("openai/gpt-oss-20b", "gpt-oss-20b"),
    ("openai/gpt-5.1-chat", "chatgpt"),
    ("meta-llama/llama-4-maverick","llama"),
    ("qwen/qwen3-30b-a3b-instruct-2507", "qwen-30b-a3b")
]

def run_evaluation(model_name, affix):
    """
    Runs a single evaluation task.
    """
    print(f"[INFO] Starting: Model={model_name}, Affix={affix}")
    
    cmd = [
        sys.executable,
        "evaluate_all_results.py",
        model_name,
        affix
    ]
    
    try:
        # Run the evaluation script. Output will be interleaved in the console.
        subprocess.run(cmd, check=True)
        return (model_name, affix, True, None)
    except subprocess.CalledProcessError as e:
        return (model_name, affix, False, f"Exit code {e.returncode}")
    except Exception as e:
        return (model_name, affix, False, str(e))

def main():
    """
    Runs evaluate_all_results.py multiple times simultaneously based on the EVALUATION_TASKS list.
    """
    print(f"Starting batch evaluation of {len(EVALUATION_TASKS)} tasks in parallel...")
    print(f"{'='*60}")
    
    # Adjust max_workers as needed. 4 is a reasonable balance for API rate limits and speed.
    max_workers = 12
    
    try:
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = {
                executor.submit(run_evaluation, model, affix): (model, affix) 
                for model, affix in EVALUATION_TASKS
            }
            
            for future in as_completed(futures):
                model_name, affix = futures[future]
                success, result = future.result()[2:] # Get success and error/None
                
                if success:
                    print(f"\n[SUCCESS] Completed evaluation for {model_name} (Affix: {affix})\n")
                else:
                    print(f"\n[ERROR] Evaluation failed for {model_name} (Affix: {affix}): {result}\n")
                    
    except KeyboardInterrupt:
        print("\n[INFO] Batch evaluation interrupted by user. Shutting down...")
        sys.exit(1)
    except Exception as e:
        print(f"\n[ERROR] An unexpected error occurred in main loop: {e}\n")

if __name__ == "__main__":
    main()
