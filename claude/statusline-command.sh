#!/usr/bin/env python3
import json, sys, os, subprocess
from datetime import datetime

data = json.load(sys.stdin)

# Time
time_str = datetime.now().strftime("%H:%M:%S")

# Directory
cwd = data.get("workspace", {}).get("current_dir") or data.get("cwd", "")
dir_display = os.path.basename(cwd) if cwd else ""

# Git branch and status
git_info = ""
try:
    branch = subprocess.run(
        ["git", "-C", cwd, "symbolic-ref", "--short", "HEAD"],
        capture_output=True, text=True, timeout=2
    ).stdout.strip()
    if branch:
        dirty_check = subprocess.run(
            ["git", "-C", cwd, "status", "--porcelain"],
            capture_output=True, text=True, timeout=2
        ).stdout.strip()
        dirty = "*" if dirty_check else ""
        git_info = f" on {branch}{dirty}"
except Exception:
    pass

# Context window
ctx = data.get("context_window", {})
used_pct = ctx.get("used_percentage")
total_in = ctx.get("total_input_tokens", 0) or 0
total_out = ctx.get("total_output_tokens", 0) or 0
total_tokens = total_in + total_out

claude_parts = []
if used_pct is not None:
    claude_parts.append(f"{used_pct}% ctx")
if total_tokens >= 1000:
    claude_parts.append(f"{total_tokens / 1000:.1f}k tok")
elif total_tokens > 0:
    claude_parts.append(f"{total_tokens} tok")

claude_str = " | ".join(claude_parts)

print(f"{time_str}  {dir_display}{git_info}  {claude_str}", end="")
