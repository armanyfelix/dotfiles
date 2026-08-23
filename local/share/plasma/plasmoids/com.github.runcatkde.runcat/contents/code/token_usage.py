#!/usr/bin/env python3
"""Summarize local Codex and Claude Code token usage for the plasmoid."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, time, timedelta
from pathlib import Path
from typing import Any, Iterable


def _number(value: Any) -> int:
    return max(0, int(value)) if isinstance(value, (int, float)) else 0


def _timestamp(value: Any) -> datetime | None:
    if not isinstance(value, str):
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def _records(paths: Iterable[Path]) -> Iterable[dict[str, Any]]:
    for path in paths:
        try:
            with path.open(encoding="utf-8") as stream:
                for line in stream:
                    try:
                        value = json.loads(line)
                    except (json.JSONDecodeError, UnicodeDecodeError):
                        continue
                    if isinstance(value, dict):
                        yield value
        except (OSError, PermissionError):
            continue


def _recent_jsonl(root: Path, day_start: datetime) -> list[Path]:
    if not root.is_dir():
        return []

    # Include one extra day so a session spanning local midnight has a
    # baseline from which today's first cumulative delta can be calculated.
    cutoff = day_start.timestamp() - timedelta(days=1).total_seconds()
    paths: list[Path] = []
    newest_path: Path | None = None
    newest_mtime = float("-inf")
    try:
        for path in root.rglob("*.jsonl"):
            try:
                mtime = path.stat().st_mtime
                if mtime > newest_mtime:
                    newest_path = path
                    newest_mtime = mtime
                if mtime >= cutoff:
                    paths.append(path)
            except OSError:
                continue
    except OSError:
        return []
    if newest_path is not None and newest_path not in paths:
        paths.append(newest_path)
    return paths


def codex_usage(
    paths: Iterable[Path], day_start: datetime, day_end: datetime
) -> dict[str, Any]:
    daily_tokens = 0
    latest_at: datetime | None = None
    latest_context = 0
    latest_window = 0

    # Codex token_count events are cumulative within one rollout file. Work
    # per file so repeated snapshots are ignored and midnight-spanning
    # sessions contribute only the positive delta occurring today.
    for path in paths:
        previous_total: int | None = None
        for record in _records([path]):
            payload = record.get("payload")
            if (
                record.get("type") != "event_msg"
                or not isinstance(payload, dict)
                or payload.get("type") != "token_count"
            ):
                continue
            info = payload.get("info")
            stamp = _timestamp(record.get("timestamp"))
            if not isinstance(info, dict) or stamp is None:
                continue

            total_usage = info.get("total_token_usage")
            last_usage = info.get("last_token_usage")
            if not isinstance(total_usage, dict):
                continue
            total = _number(total_usage.get("total_tokens"))

            local_stamp = stamp.astimezone(day_start.tzinfo)
            if local_stamp < day_start:
                previous_total = total
                continue
            if local_stamp < day_end:
                daily_tokens += total if previous_total is None else max(
                    0, total - previous_total
                )
                previous_total = total

            if latest_at is None or stamp > latest_at:
                latest_at = stamp
                latest_context = (
                    _number(last_usage.get("total_tokens"))
                    if isinstance(last_usage, dict)
                    else 0
                )
                latest_window = _number(info.get("model_context_window"))

    return {
        "available": latest_at is not None,
        "todayTokens": daily_tokens,
        "contextTokens": latest_context,
        "contextWindow": latest_window,
        "updatedAt": latest_at.astimezone().isoformat(timespec="seconds")
        if latest_at
        else "",
    }


def _claude_tokens(usage: dict[str, Any]) -> int:
    return sum(
        _number(usage.get(key))
        for key in (
            "input_tokens",
            "cache_creation_input_tokens",
            "cache_read_input_tokens",
            "output_tokens",
        )
    )


def claude_usage(
    paths: Iterable[Path],
    day_start: datetime,
    day_end: datetime,
    context_window: int,
) -> dict[str, Any]:
    # A streamed Claude response can be persisted more than once with the
    # same message id. Keep the largest observed usage for each id.
    today_by_message: dict[str, int] = {}
    latest_at: datetime | None = None
    latest_context = 0

    for record in _records(paths):
        message = record.get("message")
        stamp = _timestamp(record.get("timestamp"))
        if (
            record.get("type") != "assistant"
            or not isinstance(message, dict)
            or stamp is None
        ):
            continue
        usage = message.get("usage")
        if not isinstance(usage, dict):
            continue

        tokens = _claude_tokens(usage)
        message_id = str(message.get("id") or record.get("uuid") or "")
        local_stamp = stamp.astimezone(day_start.tzinfo)
        if day_start <= local_stamp < day_end and message_id:
            today_by_message[message_id] = max(
                today_by_message.get(message_id, 0), tokens
            )

        # The main-session input is a useful approximation of occupied
        # context. Exclude synthetic/error messages and sidechain agents.
        if (
            not record.get("isSidechain", False)
            and message.get("model") != "<synthetic>"
            and (latest_at is None or stamp > latest_at)
        ):
            latest_at = stamp
            latest_context = tokens

    return {
        "available": latest_at is not None,
        "todayTokens": sum(today_by_message.values()),
        "contextTokens": latest_context,
        "contextWindow": max(1, context_window),
        "updatedAt": latest_at.astimezone().isoformat(timespec="seconds")
        if latest_at
        else "",
    }


def summarize(home: Path, claude_context_window: int) -> dict[str, Any]:
    now = datetime.now().astimezone()
    day_start = datetime.combine(now.date(), time.min, tzinfo=now.tzinfo)
    day_end = day_start + timedelta(days=1)
    codex_paths = _recent_jsonl(home / ".codex" / "sessions", day_start)
    claude_paths = _recent_jsonl(home / ".claude" / "projects", day_start)
    return {
        "codex": codex_usage(codex_paths, day_start, day_end),
        "claude": claude_usage(
            claude_paths, day_start, day_end, claude_context_window
        ),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument("--claude-context-window", type=int, default=200_000)
    args = parser.parse_args()
    result = summarize(args.home, args.claude_context_window)
    print(json.dumps(result, separators=(",", ":")))


if __name__ == "__main__":
    main()
