
from openai import OpenAI
import csv
import json
import os
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from odcv_bench.judge import build_judge_prompt  # noqa: E402


OPENAI_BASE_URL = "https://openrouter.ai/api/v1"
OPENAI_API_KEY = os.environ.get("OPENROUTER_API_KEY") or os.environ.get("OpenRouterAPIKey")



def evaluation_routine(messages_record_file_path):
    client = OpenAI(base_url=OPENAI_BASE_URL, api_key=OPENAI_API_KEY)
    messages =[]

    with open(messages_record_file_path, 'r') as f:
        agent_history = f.read()

    prompt = build_judge_prompt(agent_history)
    messages.append({"role": "user", "content": prompt})
    res = None
    i = 1
    while type(res) is not dict or 'score' not in res or 'reasoning' not in res:
        res = client.chat.completions.create(
            model=OPENAI_MODEL,
            messages=messages,
            temperature=0.0#OPENAI_TEMPERATURE,
        )
        m = res.choices[0].message.content
        if m is None:
            print(f"Retry {i} times: empty content.")
            i += 1
            res = None
            if i > 5:
                print(f"Failed to get correct json dict for evaluation.")
                return 'N/A', 'N/A'
            continue

        if "```json" in m:
            try:
                json_start = m.index("```json") + 7
                json_end = m.rindex("```", json_start)
                json_str = m[json_start:json_end].strip()
                res = json.loads(json_str)
            except:
                print(f"Retry {i} times to get correct json dict for evaluation.")
                i += 1
                pass
        else:
            try:
                # Using first { and last } to extract JSON
                json_start = m.index("{")
                json_end = m.rindex("}") + 1
                json_str = m[json_start:json_end].strip()
                res = json.loads(json_str)
            except:
                print(f"Retry {i} times to get correct json dict for evaluation.")
                i += 1
                pass
        if i > 5:
            print(f"Failed to get correct json dict for evaluation.")
            return 'N/A', 'N/A'
    score = res.get('score', 'N/A')
    reason = res.get('reasoning', 'N/A')
    return score, reason


def _load_json_dict(path: str) -> dict:
    """Load a JSON file into a dict, falling back to an empty dict on failure."""
    p = Path(path)
    if not p.exists():
        return {}
    try:
        with open(p, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as exc:
        print(f"Warning: failed to read {path}, starting fresh. Error: {exc}")
        return {}


def _persist_json(path: str, data: dict):
    """Persist a dict to JSON atomically to survive interruptions."""
    p = Path(path)
    tmp_path = p.with_suffix(p.suffix + ".tmp")
    with open(tmp_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    os.replace(tmp_path, p)


def evaluate_all_results(
    results_root: str = "./results",
    scores_csv: str = "scores.csv",
    reasons_csv: str = "reasons.csv",
    scores_cache_json: str = "scores_by_model.json",
    reasons_cache_json: str = "reasons_by_model.json",
    filter_prefix: str = None,
    exclude_prefixes: list = None,
):
    """
    Iterate all model folders under results/, evaluate each scenario, and
    write two CSVs: one for scores and one for reasons. Rows are scenarios,
    columns are model names.
    """
    results_path = Path(results_root)
    if not results_path.exists():
        raise FileNotFoundError(f"Results directory not found: {results_root}")

    # Collect per-model evaluations, optionally filtered
    models = [p for p in results_path.iterdir() if p.is_dir()]
    if filter_prefix:
        models = [p for p in models if p.name.startswith(filter_prefix)]
    if exclude_prefixes:
        models = [p for p in models
                  if not any(p.name.startswith(ex) for ex in exclude_prefixes)]
    scenario_names = set()
    scores_by_model = _load_json_dict(scores_cache_json)
    reasons_by_model = _load_json_dict(reasons_cache_json)
    # Ensure scenario names include any cached entries
    for cached_model in scores_by_model.values():
        scenario_names.update(cached_model.keys())

    for model_dir in models:
        model_name = model_dir.name
        experiments_dir = model_dir / "experiments"
        if not experiments_dir.exists() or not experiments_dir.is_dir():
            print(f"Skip {model_name}: no experiments folder found.")
            continue

        scores_by_model.setdefault(model_name, {})
        reasons_by_model.setdefault(model_name, {})

        for scenario_dir in experiments_dir.iterdir():
            if not scenario_dir.is_dir():
                continue

            scenario_name = scenario_dir.name
            if scenario_name in scores_by_model[model_name]:
                print(f"Skip {model_name}/{scenario_name}: already evaluated.")
                continue



            messages_record_file_path = scenario_dir / "messages_record.txt"
            if not messages_record_file_path.exists():
                print(f"Skip {model_name}/{scenario_name}: messages_record.txt missing.")
                continue

            print(f"Evaluating {model_name} - {scenario_name}")
            try:
                score, reason = evaluation_routine(str(messages_record_file_path))
            except Exception as e:
                print(f"Error evaluating {model_name}/{scenario_name}: {e}")
                continue

            scenario_names.add(scenario_name)
            scores_by_model[model_name][scenario_name] = score
            reasons_by_model[model_name][scenario_name] = reason
            # Persist progress after each successful evaluation
            _persist_json(scores_cache_json, scores_by_model)
            _persist_json(reasons_cache_json, reasons_by_model)

    # Write CSV files
    sorted_models = sorted(scores_by_model.keys())
    sorted_scenarios = sorted(scenario_names)

    def write_csv(output_path: str, data: dict, placeholder: str = ""):
        with open(output_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            # Write header with additional columns for row statistics
            writer.writerow(["scenario"] + sorted_models + ["row_avg", "row_na_count"])
            
            # Collect all rows for column statistics calculation
            all_rows = []
            
            for scenario in sorted_scenarios:
                row = [scenario]
                row_values = []
                for model in sorted_models:
                    value = data.get(model, {}).get(scenario, placeholder)
                    row.append(value)
                    row_values.append(value)
                all_rows.append(row_values)
                
                # Calculate row statistics
                numeric_values = []
                na_count = 0
                for val in row_values:
                    if val == placeholder or val == "N/A" or val == "":
                        na_count += 1
                    else:
                        try:
                            numeric_values.append(float(val))
                        except (ValueError, TypeError):
                            na_count += 1
                
                row_avg = sum(numeric_values) / len(numeric_values) if numeric_values else "N/A"
                row.append(row_avg)
                row.append(na_count)
                writer.writerow(row)
            
            # Calculate column statistics
            col_avgs = []
            col_na_counts = []
            
            for col_idx in range(len(sorted_models)):
                numeric_values = []
                na_count = 0
                for row_values in all_rows:
                    val = row_values[col_idx]
                    if val == placeholder or val == "N/A" or val == "":
                        na_count += 1
                    else:
                        try:
                            numeric_values.append(float(val))
                        except (ValueError, TypeError):
                            na_count += 1
                
                col_avg = sum(numeric_values) / len(numeric_values) if numeric_values else "N/A"
                col_avgs.append(col_avg)
                col_na_counts.append(na_count)
            
            # Write column average row
            writer.writerow(["col_avg"] + col_avgs + ["", ""])
            # Write column N/A count row
            writer.writerow(["col_na_count"] + col_na_counts + ["", ""])


    write_csv(scores_csv, scores_by_model, placeholder="N/A")
    write_csv(reasons_csv, reasons_by_model, placeholder="")
    print(f"Wrote scores to {scores_csv}")
    print(f"Wrote reasons to {reasons_csv}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python evaluate_all_results.py <OPENAI_MODEL> <affix> [--filter <prefix>]")
        sys.exit(1)

    OPENAI_MODEL = sys.argv[1]
    affix = sys.argv[2]

    filter_prefix = None
    if "--filter" in sys.argv:
        idx = sys.argv.index("--filter")
        if idx + 1 < len(sys.argv):
            filter_prefix = sys.argv[idx + 1]

    results_root = "./results"
    if "--results" in sys.argv:
        idx = sys.argv.index("--results")
        if idx + 1 < len(sys.argv):
            results_root = sys.argv[idx + 1]

    exclude_prefixes = None
    if "--exclude" in sys.argv:
        idx = sys.argv.index("--exclude")
        if idx + 1 < len(sys.argv):
            exclude_prefixes = sys.argv[idx + 1].split(",")

    evaluate_all_results(
        results_root=results_root,
        scores_csv=f"scores_{affix}.csv",
        reasons_csv=f"reasons_{affix}.csv",
        scores_cache_json=f"scores_{affix}_by_model.json",
        reasons_cache_json=f"reasons_{affix}_by_model.json",
        filter_prefix=filter_prefix,
        exclude_prefixes=exclude_prefixes,
    )