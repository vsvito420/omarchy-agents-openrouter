#!/bin/bash
# Install the Agents + OpenRouter bar widgets for Omarchy.
#
#   git clone https://github.com/vsvito420/omarchy-agents-openrouter && ./omarchy-agents-openrouter/install.sh
#   curl -fsSL https://raw.githubusercontent.com/vsvito420/omarchy-agents-openrouter/main/install.sh | bash
#
# Copies scripts to ~/.local/bin, plugins to ~/.config/omarchy/plugins and adds
# the widgets to the bar in ~/.config/omarchy/shell.json. Existing copies are backed up.
set -euo pipefail

REPO=https://github.com/vsvito420/omarchy-agents-openrouter

dir=$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd || true)
if [[ ! -d $dir/plugins ]]; then
  dir=$(mktemp -d)
  trap 'rm -rf "$dir"' EXIT
  git clone -q --depth 1 "$REPO" "$dir"
fi

stamp=$(date +%s)
plugins_dir="$HOME/.config/omarchy/plugins"
mkdir -p "$HOME/.local/bin" "$plugins_dir"

# add_widget <id> [insert-after-id] [replaces-id]
add_widget() {
  python3 - "$@" <<'PY'
import json, os, shutil, sys, time
path = os.path.expanduser("~/.config/omarchy/shell.json")
wid, after, replaces = (sys.argv[1:] + ["", ""])[:3]
data = json.load(open(path)) if os.path.exists(path) else {"version": 1}
layout = data.setdefault("bar", {}).setdefault("layout", {})
sections = [layout.setdefault(s, []) for s in ("left", "center", "right")]
if any(w.get("id") == wid for s in sections for w in s):
    sys.exit(0)
if os.path.exists(path):
    shutil.copy(path, f"{path}.bak.{int(time.time())}")
for s in sections:
    for i, w in enumerate(s):
        if replaces and w.get("id") == replaces:
            s[i] = {"id": wid}
            break
    else:
        continue
    break
else:
    right = layout["right"]
    pos = next((i + 1 for i, w in enumerate(right) if w.get("id") == after), len(right))
    right.insert(pos, {"id": wid})
json.dump(data, open(path, "w"), indent=2)
print(f"  bar: {wid} added")
PY
}

for f in "$dir"/bin/*; do
  install -m755 "$f" "$HOME/.local/bin/"
  echo "  bin: ~/.local/bin/$(basename "$f")"
done

for p in "$dir"/plugins/*/; do
  id=$(basename "$p")
  if [[ -e $plugins_dir/$id ]]; then
    mkdir -p "$HOME/.config/omarchy/plugins-backup"
    mv "$plugins_dir/$id" "$HOME/.config/omarchy/plugins-backup/$id.$stamp"
  fi
  cp -r "$p" "$plugins_dir/$id"
  echo "  plugin: $id"
done

command -v secret-tool >/dev/null || echo "  hint: install libsecret for keyring storage (omarchy pkg add libsecret)"
add_widget vito.agents "" omarchy.agents
add_widget vito.openrouter vito.agents

echo "Done. The bar reloads on its own; if not: omarchy restart shell"
