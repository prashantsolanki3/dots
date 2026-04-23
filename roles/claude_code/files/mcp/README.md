# MCP Server Definitions

Drop JSON files here to add MCP servers to your Claude Code configuration.
Each file defines one or more MCP servers that get merged into `~/.claude.json`.

## File Format

Each `.json` file should contain an object with MCP server definitions:

```json
{
  "server-name": {
    "command": "npx",
    "args": ["-y", "package-name@latest"],
    "env": {
      "API_KEY": "${ENV_VAR_NAME}"
    }
  }
}
```

## Environment Variables

Use `${VAR_NAME}` syntax for secrets. Set them in your shell profile or `.env` file.
Never hardcode tokens or API keys in these files.

## Adding a New MCP Server

1. Create `<server-name>.json` in this directory
2. Run the Ansible playbook (or `make dev` to rebuild the container)
3. The server will be available in your next Claude Code session

## Removing an MCP Server

Delete the `.json` file and re-run the playbook.

## Currently Configured

- `sonarqube.json` — SonarCloud/SonarQube code analysis (requires SONARQUBE_TOKEN)
- `qmd.json` — local markdown search (hybrid BM25 + vector + rerank) over project `docs/`. Companion to the LLM-wiki pattern (see `roles/llm_wiki/`). npm package `@tobilu/qmd`; binary `qmd` on PATH. MCP: `qmd mcp` (stdio). One-time per project: `qmd collection add docs/ && qmd embed`.
