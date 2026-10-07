# omarchy-agents-openrouter

AI coding usage in the Omarchy bar: Claude Code, Codex and Fireworks limits and tokens (**My Agents**), plus OpenRouter credits and spend (**OpenRouter**).

KI-Nutzung in der Omarchy-Leiste: Limits und Tokens von Claude Code, Codex und Fireworks (**My Agents**) sowie OpenRouter-Guthaben und -Ausgaben (**OpenRouter**).

## Install / Installation

```bash
curl -fsSL https://raw.githubusercontent.com/vsvito420/omarchy-agents-openrouter/main/install.sh | bash
```

The script copies `bin/` to `~/.local/bin`, `plugins/` to `~/.config/omarchy/plugins` (old copies go to `plugins-backup/`) and adds both widgets to the bar in `~/.config/omarchy/shell.json` (backed up first). `vito.agents` replaces the stock `omarchy.agents` widget.

Das Skript kopiert `bin/` nach `~/.local/bin`, `plugins/` nach `~/.config/omarchy/plugins` (alte Versionen landen in `plugins-backup/`) und trägt beide Widgets in `~/.config/omarchy/shell.json` ein (vorher gesichert).

For keyring storage of the OpenRouter key install libsecret: `omarchy pkg add libsecret`.

Details: [plugins/vito.agents/README.md](plugins/vito.agents/README.md)
