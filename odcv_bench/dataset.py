"""Build one Inspect sample per (variation, scenario) cell.

Each sample gets its own Docker build context under .odcv_build/, assembled the
same way run_benchmarks.py assembles orchestrator_api/: the contents of
orchestrator_api.zip with the scenario's files copied over them.
"""
import json
import shutil
import zipfile
from pathlib import Path

from inspect_ai.dataset import MemoryDataset, Sample

REPO_ROOT = Path(__file__).resolve().parent.parent
ORCHESTRATOR_ZIP = REPO_ROOT / "orchestrator_api.zip"
BUILD_DIR = REPO_ROOT / ".odcv_build"

VARIATIONS = {
    "mandated": REPO_ROOT / "mandated_scenarios",
    "incentivized": REPO_ROOT / "incentivized_scenarios",
}

# Same container as the paper's orchestrator (its own Dockerfile, default
# bridge network), kept alive for `docker exec` instead of running the
# human-in-the-loop API that run.py uses.
COMPOSE_YAML = """services:
  default:
    build:
      context: .
      dockerfile: Dockerfile
    command: "tail -f /dev/null"
    init: true
    stop_grace_period: 1s
"""


def check_repo_layout() -> None:
    missing = [str(p) for p in (ORCHESTRATOR_ZIP, *VARIATIONS.values()) if not p.exists()]
    if missing:
        raise FileNotFoundError(
            "odcv_bench must be installed from a checkout of the ODCV-Bench repository "
            f"(pip install -e .); missing: {', '.join(missing)}"
        )


def list_scenarios(variation: str) -> list[str]:
    return sorted((p.name for p in VARIATIONS[variation].iterdir() if p.is_dir()), key=str.lower)


def build_context(variation: str, scenario: str) -> Path:
    """Create .odcv_build/<variation>/<scenario>/ and return its compose file."""
    scenario_dir = VARIATIONS[variation] / scenario
    context = BUILD_DIR / variation / scenario
    if context.exists():
        shutil.rmtree(context)
    context.mkdir(parents=True)
    with zipfile.ZipFile(ORCHESTRATOR_ZIP) as zf:
        for member in zf.infolist():
            parts = Path(member.filename).parts
            if member.is_dir() or len(parts) < 2 or parts[0] != "orchestrator_api":
                continue
            target = context.joinpath(*parts[1:])
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(zf.read(member))
    for item in scenario_dir.iterdir():
        target = context / item.name
        if item.is_dir():
            if target.exists():
                shutil.rmtree(target)
            shutil.copytree(item, target)
        else:
            shutil.copy2(item, target)
    compose = context / "compose.yaml"
    compose.write_text(COMPOSE_YAML, encoding="utf-8")
    return compose


def load_prompts(variation: str, scenario: str) -> tuple[str, str]:
    data = json.loads((VARIATIONS[variation] / scenario / "prompt.json").read_text(encoding="utf-8"))
    return data["system_prompt"], data["user_prompt"]


def odcv_dataset(variations: list[str], scenarios: list[str] | None) -> MemoryDataset:
    check_repo_layout()
    samples = []
    for variation in variations:
        available = list_scenarios(variation)
        if scenarios is not None:
            unknown = [s for s in scenarios if s not in available]
            if unknown:
                raise ValueError(f"Unknown scenario(s) in {VARIATIONS[variation].name}: {', '.join(unknown)}")
        for scenario in (scenarios if scenarios is not None else available):
            system_prompt, user_prompt = load_prompts(variation, scenario)
            compose = build_context(variation, scenario)
            samples.append(Sample(
                id=f"{variation}:{scenario}",
                input=user_prompt,
                metadata={"variation": variation, "scenario": scenario, "system_prompt": system_prompt},
                sandbox=("docker", compose.as_posix()),
            ))
    return MemoryDataset(samples, name="odcv_bench")
