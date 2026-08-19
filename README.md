# MTG Intelligence Platform

## Overview

MTG Intelligence Platform is a production-learning project for building tools
that help Magic: The Gathering players understand and improve their decks. The
first approved product direction is an identity-preserving Commander deck review
that protects the player's intended theme, experience, and named cards.

The current application foundation contains a FastAPI backend and a React
TypeScript frontend. Its implemented behavior is intentionally narrow: both
applications start locally, the backend exposes a health contract, and the
frontend displays whether that backend is available.

## Prerequisites

- Windows PowerShell 5.1 or newer
- Python 3.13 or newer
- Node.js `^20.19.0` or `>=22.12.0`
- npm

## Install dependencies

Run the backend setup from the repository root:

```powershell
python -m venv backend/.venv
backend\.venv\Scripts\Activate.ps1
python -m pip install -e "backend[dev]"
deactivate
```

Then install the frontend dependencies:

```powershell
cd frontend
npm install
cd ..
```

The virtual environment and `node_modules/` are local dependencies and are not
committed.

## Run the applications locally

Open two PowerShell terminals at the repository root.

In the first terminal, start FastAPI:

```powershell
backend\.venv\Scripts\Activate.ps1
python -m uvicorn app.main:app --app-dir backend --reload
```

In the second terminal, start Vite:

```powershell
cd frontend
npm run dev
```

Open `http://localhost:5173`. The page initially displays `checking`, then shows
`healthy` when the backend returns the expected health response or `unavailable`
when that response cannot be confirmed.

### Development HTTP boundary

Browser code requests the relative path `/health` from the Vite development
origin. Vite proxies that request to `http://127.0.0.1:8000/health`, whose stable
successful contract is:

```json
{"status":"ok"}
```

This same-origin development proxy avoids embedding a machine-specific backend
address in React code. It is not a production routing, deployment, or security
decision. If FastAPI is unavailable, the proxy fails visibly and the page shows
`unavailable`.

Press `Ctrl+C` in each terminal to stop its server.

## Backend quality commands

Run these commands from `backend/` with its virtual environment installed:

```powershell
cd backend
.\.venv\Scripts\python.exe -m ruff format --check app tests
.\.venv\Scripts\python.exe -m ruff check app tests
.\.venv\Scripts\python.exe -m mypy app tests
.\.venv\Scripts\python.exe -m pytest tests
cd ..
```

To apply backend formatting rather than check it:

```powershell
cd backend
.\.venv\Scripts\python.exe -m ruff format app tests
cd ..
```

## Frontend quality commands

Run these commands from `frontend/`:

```powershell
cd frontend
npm run format:check
npm run typecheck
npm run lint
npm test
npm run build
cd ..
```

The Vitest command runs once and exits without waiting for input.

## Full foundation smoke check

Before running the smoke check, stop manually running FastAPI and Vite servers so
ports `8000` and `5173` are available. Then run this command from the repository
root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke-foundation.ps1
```

The smoke check:

1. Confirms the required ports are available.
2. Starts FastAPI and waits for its exact health contract.
3. Starts Vite and waits for the frontend to become reachable.
4. Verifies `/health` through the Vite development proxy.
5. Terminates every process it started on success or failure.

The command exits `0` when the complete foundation is reachable and exits
nonzero with application logs when startup or health verification fails.

## Repository structure

- `backend/` — FastAPI application, Python configuration, and backend tests.
- `frontend/` — React TypeScript application, Vite configuration, and frontend
  tests.
- `scripts/` — cross-application development verification.
- `project/` — product vision, backlog, feature briefs, engineering tickets,
  decisions, and learning artifacts.

## Development workflow

Changes are developed on focused branches and integrated through reviewable pull
requests. Commits should have one clear reason to exist, with automated evidence
proportional to the risk of the change.
