# Backend

## Prerequisite

Python 3.13 or newer.

## Local setup

Run these commands from the repository root in PowerShell:

```powershell
python -m venv backend/.venv
backend\.venv\Scripts\Activate.ps1
python -m pip install -e "backend[dev]"
```

## Run the development server

From the repository root, with the virtual environment active:

```powershell
python -m uvicorn app.main:app --app-dir backend --reload
```

The health endpoint is available at `http://127.0.0.1:8000/health`.

## Backend quality commands

Run these commands from the `backend` directory.

Format Python files:

```powershell
python -m ruff format app tests
```

Verify formatting without modifying files:

```powershell
python -m ruff format --check app tests
```

Lint Python files:

```powershell
python -m ruff check app tests
```

Type-check Python files:

```powershell
python -m mypy app tests
```

Run backend tests:

```powershell
python -m pytest tests
```

The required quality gates are the non-modifying format, lint, type-check,
and test commands. The modifying format command is a developer helper.
