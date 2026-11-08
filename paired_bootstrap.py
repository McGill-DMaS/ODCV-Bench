"""Paired-bootstrap difference CIs for planned cross-model and across-generation contrasts.

Resamples scenarios with replacement (paired across Mandated/Incentivized
variations and across both models in a contrast) and reports the 2.5/97.5
percentiles of the bootstrap distribution of the per-replicate difference.

Also reports a cluster-level Clopper-Pearson upper bound for Claude
(0 failures over 40 scenario clusters).

Krippendorff's alpha is reported by compute_paper_stats.py (raw four-judge
alpha matching the paper); it is not duplicated here.
"""
import csv
import json
import random
from pathlib import Path

REPO = Path(__file__).resolve().parent
CUR = REPO / "existing_results/current/evaluations/judge_all/scores_final_median.csv"
PREV = REPO / "existing_results/previous/evaluations/judge_all/scores_final_median.csv"
SUMMARY_ROWS = {"col_avg", "col_MR%"}

REPS = 10000
SEED = 0


def parse_col(c):
    if c.endswith("-incentivized"):
        return c[: -len("-incentivized")], "incentivized"
    if c.endswith("-mandated"):
        return c[: -len("-mandated")], "mandated"
    return None


def load(path):
    rows = [r for r in csv.DictReader(open(path)) if r["scenario"] not in SUMMARY_ROWS]
    cols = [c for c in rows[0].keys() if parse_col(c) is not None]
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


def mr_sev(data, model, indices, variations):
    s = [data[model][v][i] for v in variations for i in indices
         if data[model][v][i] is not None]
    if not s:
        return None, None
    return 100.0 * sum(1 for x in s if x >= 3) / len(s), sum(s) / len(s)


def paired_diff(data_a, model_a, data_b, model_b, n, variations, reps, seed):
    rng = random.Random(seed)
    base = list(range(n))
    dmrs, dsevs = [], []
    for _ in range(reps):
        idx = [rng.choice(base) for _ in range(n)]
        ma, sa = mr_sev(data_a, model_a, idx, variations)
        mb, sb = mr_sev(data_b, model_b, idx, variations)
        if ma is None or mb is None:
            continue
        dmrs.append(ma - mb)
        dsevs.append(sa - sb)
    dmrs.sort(); dsevs.sort()
    def ci(arr):
        return arr[int(0.025 * len(arr))], arr[int(0.975 * len(arr)) - 1]
    return ci(dmrs), ci(dsevs)


def clopper_pearson_upper(k, n, alpha):
    """Two-sided alpha => upper bound at 1-alpha/2. For k=0: 1 - (alpha/2)^(1/n)."""
    if k != 0:
        raise NotImplementedError
    return 1.0 - (alpha / 2.0) ** (1.0 / n)


# ---------- main ----------
def fmt(x, w=5, p=1):
    return f"{x:+{w}.{p}f}"


def main():
    cur, cur_models, n = load(CUR)
    print(f"current: scenarios={n} models={len(cur_models)}")

    # Planned cross-model contrasts on current data, OVERALL panel
    contrasts = [
        ("Grok-4.20", "grok-4.20",
         "Gemini-3.1-Pro-Preview", "gemini-3.1-pro-preview"),
        ("Grok-4.20", "grok-4.20",
         "Qwen3.6-27B", "qwen3.6-27b"),
        ("Gemini-3.1-Pro-Preview", "gemini-3.1-pro-preview",
         "GPT-5.5", "gpt-5.5"),
        ("Gemini-3.1-Pro-Preview", "gemini-3.1-pro-preview",
         "Qwen3.6-27B", "qwen3.6-27b"),
        ("Llama-4-Maverick", "llama-4-maverick",
         "Claude-Opus-4.7", "claude-opus-4.7"),
        ("GPT-5.5", "gpt-5.5",
         "Claude-Opus-4.7", "claude-opus-4.7"),
    ]
    print("\n=== Planned cross-model paired contrasts (Overall) ===")
    print(f"{'A − B':<55} {'ΔMR (pp)':>22} {'ΔSev':>22}")
    for nameA, ka, nameB, kb in contrasts:
        ma, sa = mr_sev(cur, ka, range(n), ["incentivized", "mandated"])
        mb, sb = mr_sev(cur, kb, range(n), ["incentivized", "mandated"])
        (mlo, mhi), (slo, shi) = paired_diff(
            cur, ka, cur, kb, n, ["incentivized", "mandated"], REPS, SEED
        )
        print(f"{nameA + ' − ' + nameB:<55} "
              f"{ma - mb:+5.1f} [{mlo:+5.1f}, {mhi:+5.1f}]   "
              f"{sa - sb:+5.2f} [{slo:+5.2f}, {shi:+5.2f}]")

    # Across-generation contrasts: same scenarios, old -> new model
    prev, _, n_prev = load(PREV)
    assert n_prev == n
    generations = [
        ("Grok",          "grok-4.1-fast",         "grok-4.20"),
        ("GPT",           "gpt-5.1-chat",          "gpt-5.5"),
        ("Claude Opus",   "claude-opus-4.5",       "claude-opus-4.7"),
        ("Kimi K2",       "kimi-k2-0905",          "kimi-k2.6"),
        ("Qwen Small",    "qwen3-30b-a3b-2507",    "qwen3.6-27b"),
        ("Qwen Large",    "qwen3-max",             "qwen3.6-max-preview"),
        ("GLM",           "glm-4.6",               "glm-5.1"),
        ("Minimax M",     "minimax-m2",            "minimax-m2.7"),
        ("Gemini Pro",    "gemini-3-pro-preview",  "gemini-3.1-pro-preview"),
    ]
    print("\n=== Across-generation paired contrasts (New − Old, Overall) ===")
    print(f"{'Family':<14} {'ΔMR (pp)':>22} {'ΔSev':>22}")
    for fam, old_key, new_key in generations:
        mo, so = mr_sev(prev, old_key, range(n), ["incentivized", "mandated"])
        mn, sn = mr_sev(cur, new_key, range(n), ["incentivized", "mandated"])
        # paired bootstrap of (new - old) using SAME scenario indices for both
        rng = random.Random(SEED + 17)
        base = list(range(n))
        dmrs, dsevs = [], []
        for _ in range(REPS):
            idx = [rng.choice(base) for _ in range(n)]
            mn_b, sn_b = mr_sev(cur, new_key, idx, ["incentivized", "mandated"])
            mo_b, so_b = mr_sev(prev, old_key, idx, ["incentivized", "mandated"])
            if None in (mn_b, mo_b):
                continue
            dmrs.append(mn_b - mo_b)
            dsevs.append(sn_b - so_b)
        dmrs.sort(); dsevs.sort()
        mlo, mhi = dmrs[int(0.025 * len(dmrs))], dmrs[int(0.975 * len(dmrs)) - 1]
        slo, shi = dsevs[int(0.025 * len(dsevs))], dsevs[int(0.975 * len(dsevs)) - 1]
        print(f"{fam:<14} {mn - mo:+6.1f} [{mlo:+6.1f}, {mhi:+6.1f}]  "
              f"{sn - so:+5.2f} [{slo:+5.2f}, {shi:+5.2f}]")

    # Clopper-Pearson upper bound for 0/40
    ub_two = clopper_pearson_upper(0, 40, 0.05)
    ub_one = 1.0 - 0.05 ** (1.0 / 40)
    print(f"\nClopper-Pearson 0/40: two-sided 95% upper={ub_two*100:.2f}%, "
          f"one-sided 95% upper={ub_one*100:.2f}%")

if __name__ == "__main__":
    main()
