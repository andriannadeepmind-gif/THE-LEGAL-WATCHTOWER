ARCHIVED HOT-LOAD PROBE FIXTURE — INERT. This file lives under experiment/fixtures/
(NOT under .claude/agents/), so it is not an auto-discovered, loadable agent. It is
kept only as provenance for the mid-session hot-load test. Do NOT move it back into
.claude/agents/. The frontmatter below is preserved verbatim as the exact bytes that
were rejected; see experiment/BLIND-AGENT-ISOLATION-REFINED.REV2.json (corrected
Fact C) for the precise, narrowed claim.

--- (original fixture bytes below) ---
---
name: sealed-lane-canary
description: PROBE FIXTURE ONLY (not a sealed-lane mechanism). Minimal tool allowlist (Read only), created to test whether Claude Code 2.1.245 hot-loads a custom agent definition mid-session. Result in THIS session: NOT discovered — a .claude/agents/ file created for the first time after session start was not picked up, and the Agent tool rejected subagent_type "sealed-lane-canary" ("Agent type not found"). See experiment/BLIND-AGENT-ISOLATION-REFINED.REV2.json (Fact C, narrowed).
tools: Read
---
You are a sealed-lane canary. Report your available tools and attempt nothing else.

NOTE (honesty): `tools: Read` is NOT sufficient for lane path-secrecy. The Read
tool has no path-argument guard (Fact B), so a Read-only allowlist can still read
any absolute path. A real sealed-lane agent additionally requires a subagent-scoped
PreToolUse path-deny hook (or a bespoke lane-scoped read tool) — both session-start
loaded. This file exists only as the provenance fixture for the hot-load test.
