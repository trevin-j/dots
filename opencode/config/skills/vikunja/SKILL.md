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

### Bucket/View Operations

- **vikunja_listViews** — List all views for a project (list, kanban, gantt, table).
- **vikunja_listBuckets** — List all buckets (columns) in a kanban view.
- **vikunja_getView** — Get tasks from a view. For kanban views, returns buckets containing tasks.
- **vikunja_moveTaskToBucket** — Move a task into a specific bucket (column) within a view.

## Bucket-Aware Workflow

When working on a task from Vikunja, **always** manage its bucket (column) status to reflect the actual work state.

### Step 1: Discover the Board

For any project-level work:
1. Call `vikunja_listViews` with the `projectId`
2. Find the **kanban** view (check `view_kind == "kanban"`)
3. **If multiple kanban views exist, ask the user which one to use**
4. Call `vikunja_listBuckets` to see the available columns
5. Call `vikunja_getView` to see the current board state (buckets with tasks)

### Step 2: Map Buckets to Work States

Use your judgment to map bucket names to work states. Common patterns:

| Work State | Typical Bucket Names |
|------------|---------------------|
| **Backlog** | "Backlog", "Ideas", "Someday", "Icebox" |
| **Ready** | "Ready", "To Do", "Todo", "Open", "Selected" |
| **In Progress** | "In Progress", "Doing", "Active", "WIP", "Started" |
| **Blocked** | "Blocked", "On Hold", "Waiting", "Paused" |
| **Review** | "Review", "In Review", "PR", "Pending Review", "QA" |
| **Done** | "Done", "Complete", "Completed", "Closed", "Finished" |

### Step 3: Automatic Bucket Movement

**Always move the task to the appropriate bucket as work progresses:**

- **Creating a new task** → place in **Backlog** or **Ready** (whichever is the starting column)
- **Starting work on a task** → move to **In Progress**
- **Task is blocked** → move to **Blocked** and **add a comment** explaining why and what it's blocked by
- **Code is ready for review / PR opened** → move to **Review**

**Important rules:**
- If you finish a task, often don't move it to done yet. Rather, if available move to review. Else, leave in progress because typically your tasks end by submitting a pr, not committing to the default branch.
- If a project has **no kanban view** (only list/table/gantt), skip bucket logic entirely
- If a view has a `done_bucket_id` configured, moving a task to that bucket auto-marks it `done`
- If a view has a `default_bucket_id`, new tasks land there by default
- **Never guess** the bucket mapping when names are ambiguous — list the buckets and reason about them

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
4. Call `vikunja_createTask` with `projectId` and JSON. Set priority per the scale above. **Never include `hex_color` or `labels`.** Always include a very descriptive description (no markdown formatting allowed):
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
6. If the project has a kanban board, move the task to the appropriate starting bucket (usually **Backlog** or **Ready**) using `vikunja_moveTaskToBucket`.

### Working on a Task (Bucket Lifecycle)

Whenever you work on a task from Vikunja, **track its state in the kanban board:**

1. **Discover the board**: `vikunja_listViews` → find kanban view → `vikunja_listBuckets` to see columns
2. **Move to In Progress** when you start working on it
3. **Move to Blocked** if you hit an obstacle — and add a comment explaining why
4. **Move to Review** when a PR is ready or code is complete
5. **Move to Done** when finished

If the project has **no kanban view**, skip all bucket logic and just update `done` / `percent_done` as needed.

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
