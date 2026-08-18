# MTG Intelligence Platform Frontend

The `frontend/` directory contains the React client for the MTG Intelligence Platform.

## Prerequisites

- Node.js
- npm

## Setup

```powershell
npm install
```

## Development

```powershell
npm run dev
```

### Local backend boundary

During local development, browser code addresses the backend health endpoint
with the relative path `/health`. The browser sends that request to the Vite
development server at `http://localhost:5173/health`, and Vite proxies it to the
FastAPI development server at `http://127.0.0.1:8000/health`.

Because the browser communicates with the same origin that serves the frontend,
this development boundary does not require browser CORS permission from FastAPI.
The proxy is development configuration, not a production routing or security
decision. If FastAPI is unavailable, the proxy request fails visibly instead of
returning a healthy response.

## Verification

Run these commands from `frontend/`:

```powershell
npm run format:check
npm run typecheck
npm test
```

- `npm run format:check` checks the frontend files for consistent formatting.
- `npm run typecheck` checks the application source and Vite configuration
  against their TypeScript project settings without building the browser bundle.
- `npm test` runs the Vitest suite once and exits without waiting for input.

The existing lint and production-build checks remain available:

```powershell
npm run lint
npm run build
```
