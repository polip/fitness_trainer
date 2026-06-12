# AGENTS.md

## Overview

Two implementations of an AI fitness plan generator:
- **Python/Streamlit** (`app.py`) — actively maintained
- **R/Shiny** (`app.R`, `quick_chat.R`) — legacy, not focus of new work

## Commands

```bash
uv sync                            # install deps
uv run streamlit run app.py        # run (or: streamlit run app.py)
```

`APP_MODE=development` (default) — reads `mock_plan.md`, no API key needed. Set `APP_MODE=production` for live AI calls.

## Architecture

- Single-file Streamlit app (`app.py` ~360 lines) — no package structure; no tests, linter, formatter, typechecker, CI.
- AI providers/versions: Claude (`claude-haiku-4-5-20251001`), GPT (`gpt-4o-mini`), Gemini (`gemini-2.5-flash`).
- API keys: `load_dotenv()` reads `.env` first; falls back to UI text input.
- PDF generation via `weasyprint` (requires system libs: pango, harfbuzz, cairo — installed in Dockerfile).
- `reportlab` in `pyproject.toml`/`requirements.txt` but **unused**.
- `main.py` is dead code (print stub).
- `manifest.json` is for R/Shiny Posit Connect deployment — irrelevant to Python app.

## Docker

```bash
docker compose up                           # dev mode (no API key)
APP_MODE=production docker compose up       # live AI calls
```

- `python:3.12-slim` — installs pango/harfbuzz/curl. HEALTHCHECK via `curl` on `localhost:8501/_stcore/health`.
- `mock_plan.md` mounted read-only for dev mode. Dockerfile does **not** copy `.env`.

## Gotchas

- `.gitignore` has `*.json` — `manifest.json` will be silently excluded. Use `git add -f` if needed.
- `.env` is also in `.gitignore` — safe for secrets, but Docker doesn't copy it (pass via env vars or UI).
- R/Shiny app (`app.R`) has **no** env-var fallback for API keys (unlike Python version).
- `quick_chat.R` uses stale model `claude-3-5-haiku-latest` vs app.py's `claude-haiku-4-5-20251001`.
