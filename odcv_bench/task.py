"""Inspect task definition.

    inspect eval odcv_bench/task.py --model openrouter/openai/gpt-oss-20b
    inspect eval odcv_bench/task.py -T variation=mandated -T scenarios=Ai-Hiring-Assistant ...

Task options (-T): variation=both|mandated|incentivized, scenarios=A,B (default all 40),
judges=id1,id2 (OpenRouter ids; default the four paper judges).
"""
from inspect_ai import Task, task
from inspect_ai.model import GenerateConfig

from odcv_bench.dataset import VARIATIONS, odcv_dataset
from odcv_bench.judge import PAPER_JUDGES
from odcv_bench.scorer import judge_panel
from odcv_bench.solver import COMMAND_TIMEOUT_S, MAX_STEPS, TEMPERATURE, odcv_agent

# run.py gives each scenario's containers 40 minutes.
SCENARIO_TIME_LIMIT_S = 40 * 60


def _split(value: str | None) -> list[str] | None:
    if value is None:
        return None
    items = [v.strip() for v in value.split(",") if v.strip()]
    if not items:
        raise ValueError("expected at least one comma-separated value")
    if len(set(items)) != len(items):
        raise ValueError(f"duplicate values in {value!r}")
    return items


@task
def odcv_bench(variation: str = "both", scenarios: str | None = None, judges: str | None = None) -> Task:
    if variation not in ("both", *VARIATIONS):
        raise ValueError(f"variation must be one of both, {', '.join(VARIATIONS)}")
    variations = list(VARIATIONS) if variation == "both" else [variation]
    judge_list = _split(judges) or PAPER_JUDGES
    return Task(
        dataset=odcv_dataset(variations, _split(scenarios)),
        solver=odcv_agent(),
        scorer=judge_panel(judge_list),
        config=GenerateConfig(temperature=TEMPERATURE),
        time_limit=SCENARIO_TIME_LIMIT_S,
        version=1,
        metadata={
            "max_steps": MAX_STEPS,
            "command_timeout_s": COMMAND_TIMEOUT_S,
            "judges": judge_list,
            "paper": "https://arxiv.org/abs/2512.20798",
        },
    )
