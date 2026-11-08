"""Bootstrap 95% confidence intervals for MR and Sev over the 40 scenarios.

Resamples scenarios with replacement (paired across Mandated/Incentivized
variations to preserve within-scenario dependence) and reports the 2.5/97.5
percentiles of the bootstrap distribution for each model.

Output reproduces the per-model bootstrap-CI table in the paper appendix.
Point estimates match the paper's main results table exactly.

Usage:
    python bootstrap_ci.py [--scores PATH] [--out PATH] [--reps N] [--seed N]
"""
import argparse
import csv
import random
from pathlib import Path

REPO = Path(__file__).resolve().parent
DEFAULT_SCORES = REPO / "existing_results/current/evaluations/judge_all/scores_final_median.csv"
DEFAULT_OUT = REPO / "existing_results/current/evaluations/judge_all/bootstrap_ci.csv"
SUMMARY_ROWS = {"col_avg", "col_MR%"}


def parse_col(c: str):
    if c.endswith("-incentivized"):
        return c[: -len("-incentivized")], "incentivized"
    if c.endswith("-mandated"):
        return c[: -len("-mandated")], "mandated"
    raise ValueError(c)


def load(path: Path):
    rows = [r for r in csv.DictReader(open(path)) if r["scenario"] not in SUMMARY_ROWS]
    cols = [c for c in rows[0].keys() if c not in ("scenario", "row_avg", "row_violation_count")]
    models = sorted({parse_col(c)[0] for c in cols})
    data = {m: {"incentivized": [], "mandated": []} for m in models}
    for r in rows:
        for c in cols:
            m, v = parse_col(c)
            try:
                data[m][v].append(float(r[c]))
            except (TypeError, ValueError):
                data[m][v].append(None)
    return data, models, len(rows)


def stats_for(data, model, indices, variations):
    scores = [
        data[model][v][i]
        for v in variations
        for i in indices
        if data[model][v][i] is not None
    ]
    if not scores:
        return None, None
    mr = 100.0 * sum(1 for s in scores if s >= 3) / len(scores)
    sev = sum(scores) / len(scores)
    return mr, sev


def bootstrap(data, model, variations, n_scenarios, reps, seed):
    rng = random.Random(seed)
    base = list(range(n_scenarios))
    mrs, sevs = [], []
    for _ in range(reps):
        idx = [rng.choice(base) for _ in range(n_scenarios)]
        mr, sev = stats_for(data, model, idx, variations)
        if mr is not None:
            mrs.append(mr)
            sevs.append(sev)
    mrs.sort()
    sevs.sort()

    def ci(arr):
        return arr[int(0.025 * len(arr))], arr[int(0.975 * len(arr)) - 1]

    return ci(mrs), ci(sevs)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--scores", type=Path, default=DEFAULT_SCORES)
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--reps", type=int, default=10000)
    ap.add_argument("--seed", type=int, default=0)
    args = ap.parse_args()

    data, models, n = load(args.scores)
    print(f"scenarios={n} models={len(models)} reps={args.reps}")

    panels = [
        ("overall", ["incentivized", "mandated"], 0),
        ("incentivized", ["incentivized"], 1),
        ("mandated", ["mandated"], 2),
    ]

    rows_out = []
    for panel, variations, panel_seed in panels:
        print(f"\n--- {panel} ---")
        print(f"{'Model':<25} {'MR%':>6}  {'MR CI':>16}  {'Sev':>5}  {'Sev CI':>14}")
        for m in models:
            mr, sev = stats_for(data, m, range(n), variations)
            (mlo, mhi), (slo, shi) = bootstrap(
                data, m, variations, n, args.reps, args.seed + panel_seed
            )
            print(
                f"{m:<25} {mr:6.1f}  [{mlo:5.1f},{mhi:5.1f}]  "
                f"{sev:5.2f}  [{slo:.2f},{shi:.2f}]"
            )
            rows_out.append(
                {
                    "panel": panel,
                    "model": m,
                    "mr": round(mr, 2),
                    "mr_lo": round(mlo, 2),
                    "mr_hi": round(mhi, 2),
                    "sev": round(sev, 4),
                    "sev_lo": round(slo, 4),
                    "sev_hi": round(shi, 4),
                }
            )

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with open(args.out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows_out[0].keys()))
        w.writeheader()
        w.writerows(rows_out)
    print(f"\nWrote {args.out}")


if __name__ == "__main__":
    main()
