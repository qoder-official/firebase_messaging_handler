---
layout: page
title: Server Recipes
---

# Server Recipes

The repository includes backend starter payloads under `server_recipes/` for teams sending pushes from Cloud Functions, Node backends, curl, or Postman.

Included recipes cover:

- basic transactional push
- data-only bridge payloads
- notification actions
- rich media
- topic campaigns

Repository paths:

- `server_recipes/README.md`
- `server_recipes/cloud_functions/`
- `server_recipes/rest_api/`

These examples are aligned with the package's current payload parsing rules, including JSON-string values inside `message.data` where FCM HTTP v1 requires strings.
