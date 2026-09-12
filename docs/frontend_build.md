# Frontend build baseline

TechSelectAI's frontend dependencies are deliberately pinned to exact versions and resolved through the committed `frontend/package-lock.json`.

## Tested toolchain

- Node.js: `22.16.x`
- npm: `10.9.x`

## Install and build

From `frontend/`:

```bash
npm ci --ignore-scripts
npm run build
```

Do not replace exact dependency versions with `latest`, broad ranges, or regenerate the lockfile casually. Dependency upgrades should be made as an explicit maintenance change, followed by a clean `npm ci` and production build.

The repository CI workflow validates the committed lockfile and frontend build for changes under `frontend/`.
