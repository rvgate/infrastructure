#!/bin/bash
set -euo pipefail

# claude code lives in the persistent home so it can update itself
if [ ! -x ~/.local/bin/claude ]; then
    curl -fsSL https://claude.ai/install.sh | bash
fi

git config --global user.name "$GIT_AUTHOR_NAME"
git config --global user.email "$GIT_AUTHOR_EMAIL"
git config --global init.defaultBranch master
gh auth setup-git --hostname github.com

mkdir -p "$CLAUDE_WORKSPACE"
for repo in $CLAUDE_REPOSITORIES; do
    if [ ! -d "$CLAUDE_WORKSPACE/${repo#*/}/.git" ]; then
        git clone "https://github.com/$repo.git" "$CLAUDE_WORKSPACE/${repo#*/}"
    fi
done

mkdir -p ~/.vnc
x11vnc -storepasswd "$VNC_PASSWORD" ~/.vnc/passwd > /dev/null

exec supervisord -c /etc/supervisor/claude.conf
