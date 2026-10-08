# Agents-Leiste mit OpenRouter

<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="72" height="72" role="img" aria-label="Icon Agents-Leiste">
  <defs><linearGradient id="agbg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#6a2bd0"/><stop offset=".55" stop-color="#c23a8f"/><stop offset="1" stop-color="#f08a24"/></linearGradient></defs>
  <rect width="128" height="128" rx="28" fill="url(#agbg)"/>
  <g fill="#fff" fill-opacity=".3"><rect x="26" y="34" width="76" height="12" rx="6"/><rect x="26" y="58" width="76" height="12" rx="6"/><rect x="26" y="82" width="76" height="12" rx="6"/></g>
  <g fill="#fff"><rect x="26" y="34" width="58" height="12" rx="6"/><rect x="26" y="58" width="32" height="12" rx="6"/><rect x="26" y="82" width="70" height="12" rx="6"/></g>
</svg>

Omarchy bringt das Widget **Agents** mit: ein Icon in der Bar, das Limits und Verbrauch von
Claude Code, Codex und Fireworks zeigt. Ich habe es um einen Limit-Balken direkt in der Bar
und um OpenRouter erweitert.

## Was es zeigt

- **`vito.agents`** – Klon von `omarchy.agents`
  - kleiner **Füllstandsbalken direkt neben dem Icon** (Limit-Fenster bzw. verbrauchtes Guthaben)
  - Tooltip mit „Session: 42 % used“
  - Klicks auf den Balken verhalten sich wie auf das Icon
- **OpenRouter als eigener Tab** in der Agents-Leiste
  - **API-Key** → Spend heute / Woche / Monat und das Key-Limit
  - **Management-Key** (optional) → Konto-Guthaben plus Tokens nach Tag und Modell
- **`vito.openrouter`** – eigenes Bar-Widget
  - Guthaben & Spend auf einen Blick
  - Keys direkt im Panel einfügen, `r` aktualisiert

## Installieren

Quellcode: [vsvito420/omarchy-agents-openrouter](https://github.com/vsvito420/omarchy-agents-openrouter)

```bash
curl -fsSL https://vitos.app/apps/omarchy/install.sh | bash -s -- agents-openrouter
```

oder direkt von GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/vsvito420/omarchy-agents-openrouter/main/install.sh | bash
```

- ersetzt `omarchy.agents` in der Bar durch `vito.agents` und setzt `vito.openrouter` daneben
- braucht `libsecret` für den Schlüsselbund (`omarchy pkg add libsecret`, meist schon da)
- danach OpenRouter-Widget öffnen → API-Key einfügen → Enter

## So funktioniert's

- **Collector** `openrouter-agent-usage` schreibt einen Datensatz nach
  `~/.local/state/omarchy/agents/usage/openrouter.json`
  - die Agents-Leiste zeigt jeden Datensatz dort automatisch als Tab – das Plugin selbst bleibt unangetastet
- **Balken in der Bar:** liest dieselben Limit-Daten wie das Panel und zeichnet sie neben das Icon

## API-Keys bleiben privat

- Keys liegen im **Schlüsselbund** (gnome-keyring / Secret Service, via `secret-tool`),
  Dienst `openrouter-omarchy` – nicht in einer Datei, nicht im Repo
- beim Speichern gehen sie über Umgebungsvariablen an den Collector, **nie über die
  Kommandozeile** – sie tauchen also nicht in `ps` auf
- im Panel und im Datensatz steht nur ein gekürzter Hinweis wie `sk-or-v1-…abcd`
- Reihenfolge beim Lesen: `OPENROUTER_API_KEY` / `OPENROUTER_MANAGEMENT_KEY` → Schlüsselbund → Datei (nur noch als Notlösung)

<div class="callout tip" markdown="1">
Alte Klartext-Datei `~/.config/omarchy/agents/openrouter.json`? → `openrouter-secure-keys` verschiebt die Keys
in den Schlüsselbund und löscht sie aus der Datei.
</div>

## Siehe auch

- [[Omarchy]] – alle Erweiterungen und das Installationsskript
- [[AirPods unter Omarchy]], [[Energieprofil-Tacho für die Bar]]
