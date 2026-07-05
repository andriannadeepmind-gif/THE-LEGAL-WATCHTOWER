# Connecting the corpus to an AI agent (MCP)

The server speaks **MCP / JSON-RPC 2.0 over stdio** (`orchestrator.core --serve-mcp`),
so any MCP client launches it as a subprocess. stdout carries protocol frames only
(banner/logs go to stderr). Tools: `list_corpora`, `get_article`, `verify_provision`.

## 0. Build the image once
```powershell
cd C:\STAVROPOULOSLAWCORPUS
docker compose build          # produces orchestrator:latest
```

## 1. Smoke-test it by hand (no client needed)
```powershell
echo '{"jsonrpc":"2.0","id":1,"method":"initialize"}' | docker run -i --rm orchestrator:latest --serve-mcp
# → {"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05", ... }}

echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | docker run -i --rm orchestrator:latest --serve-mcp
# → lists get_article / verify_provision / list_corpora
```
`-i` (interactive stdin) is required; do **not** add `-t`.

## 2. Claude Desktop
Edit `%APPDATA%\Claude\claude_desktop_config.json` (create it if absent) with the
contents of `claude_desktop_config.json` in this folder, then **restart Claude
Desktop**. The 🔌 tools appear; ask e.g. *"verify this is the authentic Άρθρο 299"*.

The `-v …\output:/app/output:ro` mount lets `get_article` read the emitted
`article-N.proof.json` (run `--emit-proofs` first). `verify_provision` needs no
mount — it is self-contained.

## 3. Claude Code / Cursor / any MCP client
Same launcher (`command: docker`, `args: [run, -i, --rm, …, --serve-mcp]`).
For Claude Code:
```bash
claude mcp add stavropoulos-law -- docker run -i --rm \
  -v "$PWD/output:/app/output:ro" orchestrator:latest --serve-mcp
```

## 4. Running the binary directly (no Docker)
If you have the `orchestrator.core` executable on the host, the launcher is simply
`command: /path/to/orchestrator.core`, `args: ["--serve-mcp"]`.

## The point
The agent doesn't just *retrieve* — it can **verify**: `verify_provision` confirms a
text resolves to our signed Merkle root (Proof-Carrying Law, PCL-1). From
*"cite this source"* to *"verify against this root."*
