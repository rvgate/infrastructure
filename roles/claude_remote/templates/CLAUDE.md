# Carambolecomputer workspace

Managed by ansible (infrastructure repo, role `claude_remote`), local edits are overwritten.

Each directory here is a separate git repository with its own CLAUDE.md / AGENTS.md:

{% for repo in claude_remote_repositories %}
- `{{ repo.split('/')[1] }}`: github.com/{{ repo }}
{% endfor %}

## Environment

- This runs in a docker container on the production server (contabo-vds), driven through Remote Control.
- Several sessions can share this workspace. Before starting larger changes in a repository, create a
  git worktree (`git worktree add ../<repo>-<topic> -b <branch>`) instead of editing a checkout another
  session may be using.
- Commit and push with git and `gh`; both are authenticated for the repositories above.
- Use the Chrome browser tools for screenshots and checking web pages. Services started on the host are
  reachable at `host.docker.internal`.

## CI/CD

- `carambolecomputer-api`: pushing to `live` deploys to production.
- `carambolecomputer-next`: see `.github/workflows/deploy-*.yml` for beta and production deploys.
- `carambolecomputer-android`: a Vue project, the APK is built by GitHub Actions (there is no Android SDK
  here). Pushing a `<versionCode>-<versionName>` tag creates a release.
- `carambolecomputer-crawler`, `carambolecomputer-jobs`: scheduled workflows, start one with `gh workflow run`.
- Follow up on a run with `gh run watch` and report the result.

## Docker

The docker socket is the host's, so the production containers (carambolecomputer-postgres-1, ingress,
github runners, ...) are visible. Never stop, remove or recreate containers you did not start yourself.
Always run compose with a separate project name, e.g. `docker compose -p claude-api up -d`, and clean up
afterwards.
