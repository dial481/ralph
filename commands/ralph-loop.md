---
description: Start autonomous iteration loop until completion promise is met
---

# Ralph Loop - Autonomous Iteration

You are starting an autonomous work loop. Parse the user's arguments:

**Arguments provided:** $ARGUMENTS

Extract from arguments:
- **prompt**: The main task (first quoted string or unquoted text)
- **--max-iterations N**: Maximum iterations (default: 30)
- **--completion-promise TEXT**: The promise text to output when done (default: TASK_COMPLETE)

## Your Task

1. **Create the state file** using your Write tool:
   
   Write to `.claude/ralph-loop.local.md`:
```
   ---
   iteration: 1
   max_iterations: [extracted value]
   completion_promise: [extracted value]
   ---
   [The prompt/task to execute]
```

2. **Confirm loop started** by telling the user:
   - What task you'll be working on
   - Max iterations configured
   - The completion promise they should watch for

3. **Execute the task** from the prompt

4. **When genuinely complete**, output exactly:
```
   <promise>COMPLETION_PROMISE_HERE</promise>
```
   Replace COMPLETION_PROMISE_HERE with the actual promise text.

**Important**: The stop hook will intercept your exit attempts and feed the task back to you until you output the completion promise or hit max iterations. Your work persists in files between iterations.
