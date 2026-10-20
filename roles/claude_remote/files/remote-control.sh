#!/bin/bash
# Runs `claude remote-control` inside tmux, so the one-time prompts (login,
# workspace trust, enabling remote control) can be answered with:
#   docker exec -it claude-remote tmux attach -t remote-control
set -u

SESSION=remote-control

trap 'tmux kill-session -t "$SESSION" 2>/dev/null; exit 0' TERM INT

until claude auth status --json 2>/dev/null | jq -e '.loggedIn' > /dev/null; do
    echo "claude is not logged in, run: docker exec -it claude-remote claude auth login"
    sleep 30
done

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux new-session -d -s "$SESSION" -c "$CLAUDE_WORKSPACE" \
        "claude remote-control --name '$CLAUDE_SESSION_NAME' --chrome --permission-mode '$CLAUDE_PERMISSION_MODE'; echo 'remote control exited, restarting in 30s'; sleep 30"
fi

while tmux has-session -t "$SESSION" 2>/dev/null; do
    sleep 10 & wait $!
done
