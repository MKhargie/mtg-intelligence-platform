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