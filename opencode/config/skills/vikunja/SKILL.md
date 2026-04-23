---
name: vikunja
description: Manage Vikunja tasks, projects, and labels through the Vikunja REST API. Load always whenever the user mentions Vikunja, tasks, todos, task management, project organization, or asks to create/list/update/delete tasks and projects in Vikunja.
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
- **vikunja_createLabel** — Create a new label. Requires `title`; optionally `hexColor`.
- **vikunja_updateTaskLabels** — Replace all labels on a task using the bulk endpoint (`POST /tasks/{taskID}/labels/bulk`). Requires `taskId` and `labelsJson`.

## Task Fields Reference

Common fields for `createTask` and `updateTask`:

| Field | Type | Description |
|-------|------|-------------|
| title | string | **Required** for creation. Task title. |
| description | string | Task description (supports markdown). |
| done | boolean | Mark as completed. |
| due_date | string | ISO 8601 datetime (e.g., `2026-04-30T12:00:00Z`). |
| priority | integer | Task priority level. See priority scale below. |
| labels | array | **Read-only.** The Vikunja API ignores `labels` on task creation and update. Use `vikunja_updateTaskLabels` instead. |
| percent_done | number | Completion percentage (0-1). |

> **Important:** The `labels` field on a task is **read-only** in the Vikunja API. You must create the task first, then set labels via the separate `vikunja_updateTaskLabels` endpoint.

### Priority Scale

| Value | Meaning | Usage |
|-------|---------|-------|
| 5 | DO NOW | Only for actively failing production issues. Use extremely sparingly. |
| 4 | Urgent | Critical security, data loss, or major blocker. |
| 3 | High | Important feature or significant bug. |
| 2 | Medium | Useful improvement or moderate technical debt. |
| 1 | Low | Nice-to-have, cleanup, or trivial. |

### Label Conventions

**Always** include both effort and domain labels on every task:

- **Effort labels**: Use `effort:N` where N is a rough hour estimate (e.g., `effort:2`, `effort:6`, `effort:8`, `effort:15`, `effort:20`). Create the label if it does not exist.
- **Domain labels**: Use descriptive labels like `frontend`, `backend`, `security`, `adapter`, `infra`, `testing`, `a11y`, `cleanup`, `dependencies`, `performance`, `kpi`, `ingest`, `devops`. Create any missing label before assigning it.

**Never** set `hex_color` on tasks. Card colors should not be used.

## API Patterns

### Creating a Task

1. List projects with `vikunja_listProjects` to find the target `projectId`.
2. List existing labels with `vikunja_listLabels`.
3. Create any missing labels with `vikunja_createLabel` (effort and domain labels).
4. Call `vikunja_createTask` with `projectId` and JSON. Set priority per the scale above. **Never include `hex_color` or `labels`:**
   ```json
   {
     "title": "Fix login race condition",
     "description": "Concurrent 401s trigger multiple refresh() calls.",
     "priority": 4
   }
   ```
5. Immediately call `vikunja_updateTaskLabels` with the created task ID and the label array:
   ```json
   [
     {"id": 6, "title": "effort:6"},
     {"id": 8, "title": "frontend"},
     {"id": 3, "title": "security"}
   ]
   ```

### Updating a Task

Call `vikunja_updateTask` with partial JSON. **Do not include `labels`** — use `vikunja_updateTaskLabels` instead:
```json
{"done": true, "percent_done": 1.0}
```

### Updating Task Labels

Use `vikunja_updateTaskLabels` to replace all labels on a task. The bulk endpoint adds new labels, removes missing ones, and leaves existing matches untouched:
```json
[
  {"id": 6, "title": "effort:6"},
  {"id": 8, "title": "frontend"}
]
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
- When creating or updating tasks, always apply effort and domain labels per the conventions above.
- Never set `hex_color` on tasks.
- Keep task JSON minimal; only include fields the user explicitly requests.
