# Aku Code

Browser-first AI workspace prototype.

## Current build
- Responsive desktop and mobile UI
- Animated action rail with expandable [[ Working ]] status
- Live HTML artifact container with file progress
- Sandboxed live preview
- IndexedDB virtual workspace under /aku/my-project/
- @file-aware interaction surface
- Puter.js streaming adapter when available
- Local demo streaming fallback when a provider is unavailable
- Shared action UI intended for Chat, Agent and Preview

## Security
No provider secret is stored in this repository. Do not put private API keys into GitHub Pages JavaScript. Server-side secrets require a server/runtime outside static GitHub Pages.

## GitHub Pages
Publish the repository root with GitHub Pages. This is the static first build.

## Next
Add the full provider adapter registry, IndexedDB file explorer/editor, web and Python adapters, visual preview inspector, ZIP export, and production-safe authentication or proxy options.
