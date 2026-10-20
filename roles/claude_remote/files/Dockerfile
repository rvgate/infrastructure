FROM ubuntu:24.04

ARG CLAUDE_UID=1500
ARG NODE_MAJOR=22

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    DISPLAY=:99 \
    UV_PYTHON_INSTALL_DIR=/opt/uv/python \
    UV_TOOL_DIR=/opt/uv/tools \
    UV_TOOL_BIN_DIR=/usr/local/bin \
    PATH=/home/claude/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# base tools, virtual display and vnc
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl git gnupg jq less make openssh-client \
        procps python3 python3-venv ripgrep supervisor \
        tmux unzip vim x11vnc xvfb zip \
        fonts-liberation fonts-noto-color-emoji \
    && rm -rf /var/lib/apt/lists/*

# google chrome (the package also adds google's apt repository)
RUN curl -fsSLo /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get update && apt-get install -y /tmp/chrome.deb \
    && rm -rf /tmp/chrome.deb /var/lib/apt/lists/*

# nodejs, yarn (corepack) and firebase-tools
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get install -y nodejs \
    && corepack enable \
    && npm install -g firebase-tools \
    && rm -rf /var/lib/apt/lists/* /root/.npm

# github cli, docker cli and compose plugin
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSLo /etc/apt/keyrings/githubcli.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && curl -fsSLo /etc/apt/keyrings/docker.asc https://download.docker.com/linux/ubuntu/gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && echo "deb [signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y gh docker-ce-cli docker-compose-plugin docker-buildx-plugin \
    && rm -rf /var/lib/apt/lists/*

# python versions used by the projects, and poetry
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh \
    && uv python install 3.11 3.12 3.13 \
    && uv tool install poetry \
    && chmod -R a+rX /opt/uv

RUN userdel -r ubuntu \
    && useradd --uid ${CLAUDE_UID} --user-group --create-home --shell /bin/bash claude

COPY chrome-policy.json /etc/opt/chrome/policies/managed/claude.json
COPY supervisord.conf /etc/supervisor/claude.conf
COPY entrypoint.sh remote-control.sh /usr/local/bin/
RUN chmod 0755 /usr/local/bin/entrypoint.sh /usr/local/bin/remote-control.sh

USER claude
WORKDIR /home/claude

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
