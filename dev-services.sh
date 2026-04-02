#!/bin/bash
# ============================================================
# dev-services.sh — Launch workspace services in tmux
#
# Usage:
#   services      — starts app + api (2 panes)
#   services full — starts all 4 services
#   services add  — adds workers to existing session
# ============================================================

SESSION="services"
PROJECT_DIR="/projects/optizmo"
ACTION="${1:-default}"

# Attach if already running and no special action
if [ "$ACTION" = "default" ] && tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session already running — attaching. Use 'services add' to add workers."
  tmux attach-session -t "$SESSION"
  exit 0
fi

# Add worker panes to existing session
if [ "$ACTION" = "add" ]; then
  if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "No session running. Run 'services' first."
    exit 1
  fi
  tmux split-window -h -t "$SESSION" -c "$PROJECT_DIR"
  tmux split-window -h -t "$SESSION" -c "$PROJECT_DIR"
  tmux select-layout -t "$SESSION" even-horizontal
  tmux send-keys -t "$SESSION:1.3" "fish -c opt_w" C-m
  tmux send-keys -t "$SESSION:1.4" "fish -c opt_orch_w" C-m
  tmux attach-session -t "$SESSION"
  exit 0
fi

# Kill existing session if starting fresh with 'full'
if [ "$ACTION" = "full" ] && tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
fi

# Create session with app + api
tmux new-session -d -s "$SESSION" -c "$PROJECT_DIR"
tmux rename-window -t "$SESSION" "services"
tmux split-window -h -t "$SESSION" -c "$PROJECT_DIR"

tmux send-keys -t "$SESSION:1.1" "fish -c opt_app" C-m
tmux send-keys -t "$SESSION:1.2" "fish -c opt_api" C-m

# If full mode, add workers
if [ "$ACTION" = "full" ]; then
  tmux split-window -h -t "$SESSION" -c "$PROJECT_DIR"
  tmux split-window -h -t "$SESSION" -c "$PROJECT_DIR"
  tmux select-layout -t "$SESSION" even-horizontal
  tmux send-keys -t "$SESSION:1.3" "fish -c opt_w" C-m
  tmux send-keys -t "$SESSION:1.4" "fish -c opt_orch_w" C-m
else
  tmux select-layout -t "$SESSION" even-horizontal
fi

tmux attach-session -t "$SESSION"
