import { tool } from "@opencode-ai/plugin"
import * as fs from "fs"
import * as path from "path"

export const mktemp = tool({
  description: "Create a new temporary directory in the current working directory with a unique name, add it to git's exclude list if inside a git repo, and return the absolute path.",
  args: {},
  async execute() {
    const id = Math.random().toString(36).slice(2, 10)
    const dirName = `.tmp-${id}`
    const dirPath = path.resolve(process.cwd(), dirName)

    fs.mkdirSync(dirPath, { recursive: true })

    let current = process.cwd()
    while (true) {
      const gitDir = path.join(current, ".git")
      if (fs.existsSync(gitDir) && fs.statSync(gitDir).isDirectory()) {
        const excludePath = path.join(gitDir, "info", "exclude")
        if (fs.existsSync(excludePath)) {
          const content = fs.readFileSync(excludePath, "utf-8")
          const lines = content.split("\n")
          if (!lines.includes(dirName)) {
            fs.appendFileSync(excludePath, `${dirName}\n`)
          }
        } else {
          fs.mkdirSync(path.join(gitDir, "info"), { recursive: true })
          fs.writeFileSync(excludePath, `${dirName}\n`)
        }
        break
      }

      const parent = path.dirname(current)
      if (parent === current) break
      current = parent
    }

    return dirPath
  },
})

export const rmtemp = tool({
  description: "Remove a temporary directory created by mktemp. Only removes directories within the current working directory that start with '.tmp-'.",
  args: {
    dirPath: tool.schema.string().describe("The absolute path to the temporary directory to remove"),
  },
  async execute(args) {
    const resolved = path.resolve(args.dirPath)
    const base = path.basename(resolved)
    const parent = path.dirname(resolved)

    if (!base.startsWith(".tmp-")) {
      throw new Error(`Refusing to remove directory that does not start with '.tmp-': ${base}`)
    }

    if (parent !== process.cwd()) {
      throw new Error(`Refusing to remove directory outside of current working directory: ${resolved}`)
    }

    if (!fs.existsSync(resolved)) {
      return `Directory does not exist: ${resolved}`
    }

    fs.rmSync(resolved, { recursive: true, force: true })
    return `Removed ${resolved}`
  },
})

export default mktemp
