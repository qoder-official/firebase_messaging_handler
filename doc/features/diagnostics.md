---
layout: page
title: Diagnostics
---

# Diagnostics

`runDiagnostics()` surfaces practical delivery and setup signals:

- permission status
- token availability
- badge support
- background handler registration state
- pending click count
- invalid payload count

On web, diagnostics also report:

- browser notification API availability
- secure-context status
- service-worker API availability
- whether a service worker is actively controlling the page

Use diagnostics before debugging backend payloads. Many delivery problems are local setup issues.
