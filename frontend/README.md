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
