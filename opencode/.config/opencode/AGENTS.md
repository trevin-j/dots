## Subagent Usage Guidelines

Use subagents for:

1. **Parallel execution** - Perform multiple tasks simultaneously
2. **Context isolation** - Tasks that produce verbose output
3. **Specialized workflows** - Security audits, test writing, refactoring
4. **Long-running tasks** - Keep main context clean while AI works

## Long-Running Task Guidelines

For tasks that run without interruption:

1. Subagents maintain isolated context
2. Main agent stays informed via summaries
3. User remains decision-maker - subagents suggest, user approves
