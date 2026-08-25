---
name: sealed-lane-canary
description: PROBE FIXTURE ONLY (not a sealed-lane mechanism). Minimal tool allowlist (Read only), created to test whether Claude Code 2.1.245 hot-loads a custom agent definition mid-session. Result: NOT hot-loaded — the Agent tool rejected subagent_type "sealed-lane-canary" ("Agent type not found"); the agent registry is fixed at session start. See experiment/BLIND-AGENT-ISOLATION-REFINED.json (Fact C).
tools: Read
---
You are a sealed-lane canary. Report your available tools and attempt nothing else.

NOTE (honesty): `tools: Read` is NOT sufficient for lane path-secrecy. The Read
tool has no path-argument guard (Fact B), so a Read-only allowlist can still read
any absolute path. A real sealed-lane agent additionally requires a subagent-scoped
PreToolUse path-deny hook (or a bespoke lane-scoped read tool) — both session-start
loaded. This file exists only as the provenance fixture for the hot-load test.
