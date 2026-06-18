# Berj RE Photos Status

## User-Owned Notes

- Purpose: AI-assisted commercial real estate photo editing pipeline for accurate marketing deliverables.
- Current client target: Steve Thomas / Pattah Development retail property set.

<!-- AUTO-MANAGED -->

## Key Config

- Project path: `/home/dev/projects/Berj-RE-Photos-`
- Primary MCP target: `maorcc/gimp-mcp`
- Alternate MCP reference: `abelduarte/gimp-mcp`
- Task prefix: `CT`
- Git branch: `main`

## Architecture

- Phase 1 is a single-image atomic worker architecture.
- `agents/editor-worker.md` defines the editing worker prompt for one-image jobs.
- `agents/qa-reviewer.md` reserves the post-edit review role for Phase 2.
- `schemas/edit-instruction.json` defines the job payload consumed by the worker.
- `docs/gimp-mcp-setup.md` captures local worker setup guidance for GIMP and the MCP bridge.
- `scripts/setup-gimp-headless.sh` bootstraps a future worker environment without being executed during scaffold.

## File Map

- `README.md`: project overview, architecture, roadmap, revenue model, and current known issues.
- `STATUS.md`: living project state and file map.
- `.gitignore`: ignores local dependency clones and log output from setup experiments.
- `agents/editor-worker.md`: core system prompt for the atomic editor worker.
- `agents/qa-reviewer.md`: Phase 2 reviewer stub.
- `schemas/edit-instruction.json`: edit job schema.
- `docs/gimp-mcp-setup.md`: setup guide for GIMP and gimp-mcp.
- `scripts/setup-gimp-headless.sh`: bootstrap script for local headless-capable setup.

## Last 10 Changes

- `CT-039`: scaffolded the repository with README, STATUS, agent prompts, edit schema, setup guide, `.gitignore`, and bootstrap script for GIMP MCP worker setup.

## Known Issues

- `maorcc/gimp-mcp` upstream docs still describe a plugin-started server from inside GIMP rather than a clearly documented unattended private headless worker flow.
- The scaffold intentionally does not run GIMP or validate the MCP bridge yet because that is outside this task's scope.
