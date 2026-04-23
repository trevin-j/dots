import { tool } from "@opencode-ai/plugin"

const HELPER_PATH = `${process.env.OPENCODE_CONFIG_DIR}/tools/vikunja-helper.sh`

async function runHelper(args: string[]): Promise<string> {
  const proc = Bun.spawn(["bash", HELPER_PATH, ...args], {
    stdout: "pipe",
    stderr: "pipe",
  })
  const result = await new Response(proc.stdout).text()
  const err = await new Response(proc.stderr).text()
  if (err && !result) {
    throw new Error(err.trim())
  }
  return result.trim()
}

export default tool({
  description: "Check if Vikunja API credentials are configured and valid. Always call this first before using other vikunja tools. Returns JSON with configured, valid, and user fields.",
  args: {},
  async execute() {
    return runHelper(["status"])
  },
})

export const listProjects = tool({
  description: "List all Vikunja projects the user has access to. Returns a JSON array of projects.",
  args: {},
  async execute() {
    return runHelper(["list_projects"])
  },
})

export const listTasks = tool({
  description: "List Vikunja tasks. Optionally filter by project ID. Returns a JSON array of tasks.",
  args: {
    projectId: tool.schema.number().optional().describe("Optional project ID to filter tasks"),
  },
  async execute(args) {
    if (args.projectId !== undefined) {
      return runHelper(["list_tasks", String(args.projectId)])
    }
    return runHelper(["list_tasks"])
  },
})

export const getTask = tool({
  description: "Get a specific Vikunja task by its ID. Returns the task as JSON.",
  args: {
    taskId: tool.schema.number().describe("The task ID"),
  },
  async execute(args) {
    return runHelper(["get_task", String(args.taskId)])
  },
})

export const createTask = tool({
  description: "Create a new Vikunja task in a project. Provide the project ID and a JSON object with task fields (title is required). Returns the created task as JSON.",
  args: {
    projectId: tool.schema.number().describe("The project ID to create the task in"),
    task: tool.schema.string().describe("JSON object with task fields. Required: title. Optional: description, due_date, priority, labels, etc."),
  },
  async execute(args) {
    return runHelper(["create_task", String(args.projectId), args.task])
  },
})

export const updateTask = tool({
  description: "Update an existing Vikunja task. Provide the task ID and a JSON object with fields to update. Returns the updated task as JSON.",
  args: {
    taskId: tool.schema.number().describe("The task ID to update"),
    task: tool.schema.string().describe("JSON object with fields to update (e.g., title, description, done, due_date, priority, hex_color)"),
  },
  async execute(args) {
    return runHelper(["update_task", String(args.taskId), args.task])
  },
})

export const deleteTask = tool({
  description: "Delete a Vikunja task by its ID.",
  args: {
    taskId: tool.schema.number().describe("The task ID to delete"),
  },
  async execute(args) {
    return runHelper(["delete_task", String(args.taskId)])
  },
})

export const listLabels = tool({
  description: "List all Vikunja labels the user has access to. Returns a JSON array of labels.",
  args: {},
  async execute() {
    return runHelper(["list_labels"])
  },
})

export const createLabel = tool({
  description: "Create a new Vikunja label. Provide the label title (required) and optionally a hex color without the # prefix. Returns the created label as JSON.",
  args: {
    title: tool.schema.string().describe("The label title (e.g., 'effort:8', 'frontend', 'security')"),
    hexColor: tool.schema.string().optional().describe("Optional hex color without # (e.g., 'ff0000')"),
  },
  async execute(args) {
    const cmdArgs = ["create_label", args.title]
    if (args.hexColor !== undefined) {
      cmdArgs.push(args.hexColor)
    }
    return runHelper(cmdArgs)
  },
})

export const updateTaskLabels = tool({
  description: "Replace all labels on a Vikunja task using the bulk endpoint. Pass a JSON array of label objects with id and title. Any existing labels not in the list will be removed; new ones will be added; existing matches are left untouched. Returns the updated task labels as JSON.",
  args: {
    taskId: tool.schema.number().describe("The task ID to update labels on"),
    labelsJson: tool.schema.string().describe('JSON array of label objects, e.g. [{"id":1,"title":"effort:8"},{"id":7,"title":"backend"}]'),
  },
  async execute(args) {
    const payload = JSON.stringify({ labels: JSON.parse(args.labelsJson) })
    return runHelper(["bulk_update_labels", String(args.taskId), payload])
  },
})

export const listViews = tool({
  description: "List all views for a Vikunja project. Returns a JSON array of views (list, kanban, gantt, table).",
  args: {
    projectId: tool.schema.number().describe("The project ID"),
  },
  async execute(args) {
    return runHelper(["list_views", String(args.projectId)])
  },
})

export const listBuckets = tool({
  description: "List all buckets (columns) in a Vikunja kanban view. Returns a JSON array of buckets.",
  args: {
    projectId: tool.schema.number().describe("The project ID"),
    viewId: tool.schema.number().describe("The view ID (must be a kanban view)"),
  },
  async execute(args) {
    return runHelper(["list_buckets", String(args.projectId), String(args.viewId)])
  },
})

export const getView = tool({
  description: "Get tasks from a Vikunja view. For kanban views, returns buckets containing tasks. For list/table/gantt views, returns a flat array of tasks.",
  args: {
    projectId: tool.schema.number().describe("The project ID"),
    viewId: tool.schema.number().describe("The view ID"),
  },
  async execute(args) {
    return runHelper(["get_view", String(args.projectId), String(args.viewId)])
  },
})

export const moveTaskToBucket = tool({
  description: "Move a Vikunja task into a specific bucket (column) within a view. This is how you move tasks between kanban columns.",
  args: {
    projectId: tool.schema.number().describe("The project ID"),
    viewId: tool.schema.number().describe("The view ID containing the bucket"),
    bucketId: tool.schema.number().describe("The target bucket (column) ID"),
    taskId: tool.schema.number().describe("The task ID to move"),
  },
  async execute(args) {
    return runHelper([
      "move_task_bucket",
      String(args.projectId),
      String(args.viewId),
      String(args.bucketId),
      String(args.taskId),
    ])
  },
})
