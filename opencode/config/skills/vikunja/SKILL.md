---
name: vikunja
description: Manage Vikunja tasks, projects, and labels through the Vikunja REST API. Use when the user mentions Vikunja, tasks, todos, task management, project organization, or asks to create/list/update/delete tasks and projects in Vikunja.
license: MIT
author: DevTrev
---

# Skill: Vikunja Integration

Interact with a Vikunja instance via its REST API to manage tasks, projects, and labels.

## Prerequisites

- Vikunja API credentials must be configured. Call `vikunja_status` to verify.
- If not configured, instruct the user to run `opencode-setup-vikunja` and stop until setup is complete.

## Setup

1. User creates an API token in Vikunja UI (Settings > API Tokens).
2. User runs `opencode-setup-vikunja` in their shell.
3. Script prompts for base URL and token, validates them, and stores in `~/.local/share/vikunja/credentials` (chmod 600).

## Authentication

All API calls use `Authorization: Bearer <token>` header. Credentials are read from the helper script automatically.

## Core Workflow

Always check status first before any other operation:

```
vikunja_status → if not configured, prompt user to run opencode-setup-vikunja
```

## Available Tools

### Read Operations

- **vikunja_listProjects** — List all accessible projects.
- **vikunja_listTasks** — List tasks. Optionally filter by `projectId`.
- **vikunja_getTask** — Get a single task by ID.
- **vikunja_listLabels** — List all accessible labels.

### Write Operations

- **vikunja_createTask** — Create a task in a project. Requires `projectId` and a JSON task object.
- **vikunja_updateTask** — Update an existing task. Requires `taskId` and a JSON object with fields to change.
- **vikunja_deleteTask** — Delete a task by ID.

## Task Fields Reference

Common fields for `createTask` and `updateTask`:

| Field | Type | Description |
|-------|------|-------------|
| title | string | **Required** for creation. Task title. |
| description | string | Task description (supports markdown). |
| done | boolean | Mark as completed. |
| due_date | string | ISO 8601 datetime (e.g., `2026-04-30T12:00:00Z`). |
| priority | integer | Task priority level. |
| hex_color | string | Color in hex format (e.g., `#ff0000`). |
| percent_done | number | Completion percentage (0-1). |

## API Patterns

### Creating a Task

1. List projects with `vikunja_listProjects` to find the target `projectId`.
2. Call `vikunja_createTask` with `projectId` and JSON:
   ```json
   {"title": "Buy groceries", "description": "Milk, eggs, bread"}
   ```

### Updating a Task

Call `vikunja_updateTask` with partial JSON:
```json
{"done": true, "percent_done": 1.0}
```

### Filtering Tasks

Call `vikunja_listTasks` with optional `projectId`:
- Without `projectId`: returns tasks across all projects.
- With `projectId`: returns tasks in that project only.

## Error Handling

- **401 Unauthorized**: Invalid or expired token. Ask user to re-run `opencode-setup-vikunja`.
- **403 Forbidden**: No access to project/task. Do not retry.
- **404 Not Found**: Task or project does not exist.
- **Connection errors**: Vikunja instance may be unreachable. Report the error.

## Safety Guidelines

- Always confirm destructive actions (delete) with the user.
- When creating tasks, ensure the project ID is valid first.
- Keep task JSON minimal; only include fields the user explicitly requests.
