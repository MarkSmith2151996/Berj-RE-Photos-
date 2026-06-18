# Berj RE Photos

AI-assisted commercial real estate photo editing pipeline for accurate, institutional-quality marketing images.

## Current Phase

Phase 1: Atomic Unit

One worker agent receives one image plus a structured edit instruction object, edits the image in GIMP through MCP, verifies each major step visually, exports the result, and flags uncertain outcomes for human review.

## Architecture

```text
Client images
    |
    v
Dispatcher
    |
    v
Parallel Armada workers
  - worker 1 -> headless GIMP instance
  - worker 2 -> headless GIMP instance
  - worker N -> headless GIMP instance
    |
    v
QA agent (post-check only, no edits)
    |
    v
Human review (Berj)
```

## Stack

- GIMP 3.2+ in headless-capable worker environments
- `maorcc/gimp-mcp` as the primary MCP bridge target
- Custodian Armada for future worker orchestration
- OpenAI Agents SDK / Claude Code for agent execution

## Project Structure

```text
.
├── agents/
│   ├── editor-worker.md
│   └── qa-reviewer.md
├── docs/
│   └── gimp-mcp-setup.md
├── schemas/
│   └── edit-instruction.json
├── scripts/
│   └── setup-gimp-headless.sh
├── .gitignore
├── README.md
└── STATUS.md
```

## Editing Standard

Client work must remain 100% accurate to the actual property.

- Preserve buildings, tenants, outparcels, monument signs, logos, branding, and landscaping layouts.
- Do not recreate unreadable signs or invent missing details.
- Improve composition, tone, clarity, and cleanup without changing the underlying real estate facts.
- Target institutional-quality deliverables suitable for offering memorandums, websites, proposals, and investor presentations.

## Phase Roadmap

1. Atomic Unit
2. QA Agent
3. Armada Integration
4. Client Intake

## Revenue Model

- Leads originate through Berj's mom's brokerage network.
- Berj owns client communication and review.
- The AI pipeline handles production throughput and consistency.
- Service tiers:
  - Standard: 3-5 days
  - Priority: 24-48 hours
  - Rush: same day

## Known Issues

- `maorcc/gimp-mcp` documents a plugin-driven server started from inside GIMP, but its README does not describe a fully automated private headless bridge. The bootstrap guide in this repo documents a practical headless launch path, but real integration details may need adjustment during implementation.
- `abelduarte/gimp-mcp` appears better aligned with containerized private workers, but this repo is currently scaffolded around the `maorcc/gimp-mcp` tool surface requested in the task.
