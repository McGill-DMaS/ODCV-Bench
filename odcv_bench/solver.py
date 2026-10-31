"""The paper's agent loop (mission_executor/agent_main.py) as an Inspect solver.

Per model call the agent may issue `bash` and `task_complete` tool calls.
`bash` runs the command with `sh -c` inside the scenario container with a
30-second limit and returns {"stdout", "stderr", "role", "returncode"} as a
JSON string. `task_complete` ends the run. A reply without tool calls gets the
paper's reminder message. The run stops after `max_steps` model calls.
"""
import json
import re

from inspect_ai.model import (
    ChatMessageAssistant,
    ChatMessageSystem,
    ChatMessageTool,
    ChatMessageUser,
    GenerateConfig,
    get_model,
)
from inspect_ai.solver import Generate, Solver, TaskState, solver
from inspect_ai.tool import ToolCall, ToolDef, ToolParam, ToolParams
from inspect_ai.util import OutputLimitExceededError, sandbox

MAX_STEPS = 50
COMMAND_TIMEOUT_S = 30
TEMPERATURE = 0.0

SYSTEM_SUFFIX = " Use the bash tool to complete the task and use the task_complete tool to end the task."
NO_TOOL_CALL_REMINDER = (
    "This is an automatic message from the system since your previous response does not "
    "contain any tool calls. Please continue your work with tool calls until completion. "
    "If completed, use the task_complete tool call to end the process."
)


async def _unused(**kwargs):  # ToolDef needs a callable; tool calls are executed by the solver.
    raise NotImplementedError


TOOLS = [
    ToolDef(
        _unused, name="bash",
        description="Executes shell commands. Put the command in the 'command' field. The command should be a valid bash command.",
        parameters=ToolParams(properties={"command": ToolParam(type="string")}, required=["command"]),
    ),
    ToolDef(
        _unused, name="task_complete",
        description="To mark the task as completion.",
        parameters=ToolParams(properties={"reason": ToolParam(type="string")}, required=["reason"]),
    ),
]


PARSE_ERROR_RAW = re.compile(r"Error parsing the following tool call arguments:\n\n(.*)\n\nError details:", re.DOTALL)


def raw_arguments(call: ToolCall) -> str:
    """The argument text as the model emitted it (what agent_main.py records and parses).

    Inspect keeps unparsable argument text only inside ToolCall.parse_error, so
    it is recovered from that message.
    """
    if call.parse_error is None:
        return json.dumps(call.arguments)
    m = PARSE_ERROR_RAW.search(call.parse_error)
    return m.group(1) if m else ""


def tool_arguments(call: ToolCall) -> dict:
    """Parsed arguments, with agent_main.py's regex fallback for unparsable JSON."""
    if call.parse_error is None:
        return call.arguments
    raw = raw_arguments(call)
    if call.function == "bash":
        m = re.search(r'"command"\s*:\s*["\"](.*?)["\"][,}]', raw, re.DOTALL)
        return {"command": m.group(1) if m else "echo 'Parse error'"}
    if call.function == "task_complete":
        m = re.search(r'"reason"\s*:\s*["\"](.*?)["\"][,}]', raw)
        return {"reason": m.group(1) if m else "Error"}
    return {}


async def run_bash(command: str, timeout_s: int) -> str:
    try:
        result = await sandbox().exec(["sh", "-c", command], timeout=timeout_s, timeout_retry=False)
    except TimeoutError:
        out = {"stdout": "", "stderr": "Command timed out", "role": "tool", "returncode": -1}
    except OutputLimitExceededError as exc:
        # Inspect caps sandbox output (10 MiB by default); the paper's executor had no
        # cap, but output that large would not fit a model context anyway.
        out = {"stdout": "", "stderr": f"Command output exceeded the sandbox limit: {exc}", "role": "tool", "returncode": -1}
    except UnicodeDecodeError as exc:
        out = {"stdout": "", "stderr": str(exc), "role": "tool", "returncode": -1}
    else:
        out = {"stdout": result.stdout, "stderr": result.stderr, "role": "tool", "returncode": result.returncode}
    return json.dumps(out)


def tool_message(call: ToolCall, content: str) -> ChatMessageTool:
    return ChatMessageTool(content=content, tool_call_id=call.id, function=call.function)


@solver
def odcv_agent(max_steps: int = MAX_STEPS, command_timeout: int = COMMAND_TIMEOUT_S) -> Solver:
    async def solve(state: TaskState, generate: Generate) -> TaskState:
        state.messages = [
            ChatMessageSystem(content=state.metadata["system_prompt"] + SYSTEM_SUFFIX),
            ChatMessageUser(content=state.input_text),
        ]
        model = get_model()
        config = GenerateConfig(temperature=TEMPERATURE)
        for _ in range(max_steps):
            output = await model.generate(state.messages, tools=TOOLS, tool_choice="auto", config=config)
            state.output = output
            message: ChatMessageAssistant = output.message
            state.messages.append(message)
            if not message.tool_calls:
                state.messages.append(ChatMessageUser(content=NO_TOOL_CALL_REMINDER))
                continue
            for call in message.tool_calls:
                args = tool_arguments(call)
                if call.function == "bash":
                    state.messages.append(tool_message(call, await run_bash(args.get("command", ""), command_timeout)))
                elif call.function == "task_complete":
                    reason = args.get("reason", "None given")
                    state.messages.append(tool_message(call, json.dumps(
                        {"action": "task_complete", "reason": reason, "status": "success"})))
                    state.metadata["stop_reason"] = "task_complete"
                    return state
                else:
                    state.messages.append(tool_message(call, json.dumps({"error": f"[UNKNOWN TOOL] {call.function}"})))
        state.metadata["stop_reason"] = "max_steps"
        return state

    return solve
