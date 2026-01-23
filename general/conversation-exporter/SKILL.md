---
name: conversation-exporter
description: Export Claude Code conversation history to markdown format. Use when you need to: (1) Save important conversations as reference documents, (2) Share conversation history with others, (3) Create documentation from debugging sessions, (4) Archive project-related conversations for future reference.
---

# Conversation Exporter

## Overview

This skill exports Claude Code conversation history files (`.jsonl`) to clean, readable markdown format. It helps you preserve important conversations, create documentation from debugging sessions, and share knowledge with your team.

### Conversation File Location

Claude Code stores conversation history in:
```
~/.claude/projects/<workspace-path>/<session-id>.jsonl
```

Example:
```
/Users/xiaoyuliu/.claude/projects/-Users-xiaoyuliu-Documents-github-volaris-web/f0eb6929-aad2-45f5-aaf9-898e1be823b7.jsonl
```

---

## Quick Start

### Export Current Session

The easiest way to export your current conversation:

1. **Just ask**: "Export this conversation to markdown"
2. **Choose mode**: Claude will ask you to select from `minimal`, `standard`, or `detailed`
3. **Review output**: Check the generated markdown
4. **Save file**: File is automatically saved with date stamp

**Result**: `conversation-export_YYYYMMDD.md` in your current directory

### Export Specific Conversation

To export a specific conversation file:

"Export `~/.claude/projects/.../session-id.jsonl` to markdown"
- Specify the full path to the `.jsonl` file
- Claude will ask you to choose the export mode
- Optionally specify output location and mode in your request

---

## Export Modes

### Mode 1: Minimal (Default) 📝

**Best for**: Quick reference, sharing conversations, clean reading

**Includes**:
- ✅ User messages (questions and requests)
- ✅ Assistant responses (text only)
- ✅ Timestamps
- ❌ Tool calls
- ❌ Tool outputs
- ❌ Code diffs

**Example Output**:
```markdown
# Conversation Export

**Generated**: 2026-01-23 15:30:45

---

## User - 2026-01-23 09:45:34

How do I fix the CORS error in my API?

## Assistant - 2026-01-23 09:46:12

I'll help you fix the CORS error. First, let me check your current configuration...
```

**Use cases**:
- Creating reference documents
- Sharing conversation with team
- Quick review of what was discussed
- Documenting project decisions

---

### Mode 2: Standard 🔧

**Best for**: Technical documentation, debugging guides, implementation details

**Includes everything in Minimal, plus**:
- ✅ Tool calls made (Read, Edit, Bash, etc.)
- ✅ Tool parameters (file paths, commands)
- ✅ Request metadata
- ❌ Tool outputs/results
- ❌ Code diffs

**Example Output**:
```markdown
## User - 2026-01-23 10:15:22

I'm getting CORS errors when trying to access the API...

**Tool Calls**:
- `Read`: /azure-functions/src/index.js
- `Bash`: `curl https://api.example.com/health`

## Assistant - 2026-01-23 10:18:45

The CORS configuration needs to be updated. Let me check the current headers...

**Tool Calls**:
- `Bash`: `az functionapp cors add ...`
```

**Use cases**:
- Technical documentation
- Debugging guides
- Step-by-step tutorials
- Implementation references

---

### Mode 3: Detailed 🔍

**Best for**: Complete records, comprehensive documentation, forensic analysis

**Includes everything in Standard, plus**:
- ✅ Tool outputs and results
- ✅ Code diffs from Edit operations
- ✅ File contents read by Read tool
- ✅ Error messages and stack traces
- ✅ Full execution context

**Example Output**:
```markdown
## User - 2026-01-23 10:15:22

I'm getting CORS errors when trying to access the API...

**Tool Calls**:
- `Read`: /azure-functions/src/index.js

**Result**:
```javascript
const { handleStep1, ... } = require('./interpret-steps');
return handleStep1(request, user, clientIP, corsHeaders);
```

- `Bash`: `curl https://api.example.com/health`

**Result**:
```json
{"status":"ok","time":"..."}
```

## Assistant - 2026-01-23 10:18:45

Found the issue! The function name is incorrect. It should be `handleStep1Stream`...

**Tool Calls**:
- `Edit`: /azure-functions/src/index.js

**Changes**:
```diff
- const { handleStep1, ... } = require('./interpret-steps');
+ const { handleStep1Stream, ... } = require('./interpret-steps');
```
```

**Use cases**:
- Complete troubleshooting records
- Comprehensive documentation
- Forensic analysis of issues
- Creating detailed tutorials

---

## Usage Examples

### Example 1: Quick Reference (Minimal)

**Request**: "Export this conversation to markdown"

**Output**: Clean conversation with just user questions and assistant answers

**File**: `conversation-export_20260123.md`

---

### Example 2: Technical Guide (Standard)

**Request**: "Export this conversation in standard mode to `debugging-cors.md`"

**Output**: Conversation + tool calls (which files were read, which commands were run)

**File**: `debugging-cors.md`

---

### Example 3: Complete Documentation (Detailed)

**Request**: "Export `~/.claude/projects/.../session.jsonl` to `full-record.md` in detailed mode"

**Output**: Everything including tool outputs, code diffs, error messages

**File**: `full-record.md`

---

## File Naming

### Default Naming

If you don't specify a filename:
```
conversation-export_YYYYMMDD.md
```

Example: `conversation-export_20260123.md`

### Custom Naming

You can specify any filename:
- "Export to `sse-fix-reference.md`"
- "Export to `debugging-session-01.md`"
- "Export to `project-setup-guide.md`"

---

## How the Export Works

### Script Location
```
~/.claude/skills/conversation-exporter/scripts/export-conversation.py
```

### Process

1. **Locate conversation file**
   - Current session: Automatically detected
   - Specific session: Use full path to `.jsonl` file

2. **Parse JSONL format**
   - Read line by line (each line is a JSON object)
   - Extract user and assistant messages
   - Filter out noise (progress, system messages)

3. **Extract content**
   - User messages: Questions, requests, feedback
   - Assistant messages: Responses, explanations, code
   - Tool calls: Standard and detailed modes only
   - Tool outputs: Detailed mode only

4. **Format as markdown**
   - Add timestamps
   - Format code blocks with syntax highlighting
   - Create clear sections
   - Preserve conversation flow

5. **Save to file**
   - Default: Current directory
   - Custom: Any path you specify
   - Naming: Your choice or auto-generated

---

## Conversation File Structure

### JSONL Format

Each line in the `.jsonl` file is a JSON object:

```json
{
  "type": "user|assistant",
  "message": {
    "role": "user|assistant",
    "content": [
      {
        "type": "text",
        "text": "Message content here"
      }
    ]
  },
  "timestamp": "2026-01-23T09:45:34.160Z",
  "uuid": "unique-message-id"
}
```

### Message Types

- **`user`** (186 in typical session): User input, questions, requests
- **`assistant`** (309): Assistant responses, explanations
- **`progress`** (1020): Tool execution updates (noise, filtered out)
- **`system`** (3): System messages (usually filtered)
- **`queue-operation`** (11): Internal operations (filtered)
- **`file-history-snapshot`** (21): File changes (can be included in detailed mode)

---

## Advanced Features

### Filtering by Time Range

You can export specific time ranges:

"Export messages from 2026-01-23 09:00 to 10:00"

### Filtering by Content

You can search for specific topics:

"Export only messages about CORS configuration"

### Combining Modes

You can create multiple exports:

1. "Export minimal version to `quick-ref.md`"
2. "Export detailed version to `full-doc.md`"

---

## Tips and Best Practices

### When to Use Each Mode

**Use Minimal** for:
- Sharing with non-technical stakeholders
- Quick reference documents
- Email summaries
- Meeting notes

**Use Standard** for:
- Technical documentation
- Debugging guides
- Team knowledge base
- Code review summaries

**Use Detailed** for:
- Complete audit trails
- Forensic analysis
- Comprehensive tutorials
- Legal/compliance records

### File Organization

Create a dedicated directory for conversation exports:

```
project-docs/
├── conversations/
│   ├── 2026-01-23_sse-fix.md
│   ├── 2026-01-24_cors-debug.md
│   └── 2026-01-25_deployment.md
├── guides/
│   └── setup-guide.md
└── references/
    └── api-troubleshooting.md
```

### Regular Exports

Make it a habit to export important conversations:
- After resolving critical bugs
- After major feature implementations
- After architectural decisions
- Before significant refactors

---

## Troubleshooting

### Issue: "Conversation file not found"

**Solution**:
- Check the path is correct
- Use tab completion to verify file exists
- Current session: Use "this conversation" instead of path

### Issue: "Empty output"

**Solution**:
- Verify the `.jsonl` file has content
- Check that file isn't corrupted
- Try exporting in detailed mode to see all messages

### Issue: "Missing tool outputs"

**Solution**:
- Use `detailed` mode instead of `minimal` or `standard`
- Tool outputs are only included in detailed mode

---

## Examples in Practice

### Example: Creating a Bug Fix Reference

**Situation**: You just fixed a critical bug and want to document it for future reference.

**Action**: "Export this conversation in detailed mode to `bug-fix-sse-streaming.md`"

**Result**: Complete documentation including:
- Problem description
- Investigation steps
- Root cause analysis
- Solution with code changes
- Verification steps
- All tool outputs and error messages

### Example: Sharing with Team

**Situation**: You need to share a conversation about API design with your team.

**Action**: "Export this conversation in minimal mode to `api-design-discussion.md`"

**Result**: Clean, readable conversation focusing on:
- Design questions
- Decisions made
- Rationale and tradeoffs
- No tool noise

### Example: Creating a Tutorial

**Situation**: You walked through setting up GitHub OAuth and want to create a tutorial.

**Action**: "Export this conversation in standard mode to `github-oauth-tutorial.md`"

**Result**: Step-by-step guide including:
- Commands that were run
- Files that were edited
- Configuration values
- Clear explanations

---

## Implementation Workflow

When using this skill to export a conversation, follow this workflow:

1. **User Request**: User asks to export conversation (e.g., "Export this conversation to markdown")

2. **Ask for Mode** (CRITICAL): Always ask the user which export mode they want:
   - Use AskUserQuestion to present the three mode options
   - Explain what each mode includes
   - Let user choose based on their use case

3. **Locate Conversation File**:
   - For "this conversation": Find the current session's .jsonl file
   - For specific file: Use the provided path

4. **Execute Export**:
   - Run the Python script with chosen mode
   - Parse JSONL file
   - Filter and format messages
   - Generate markdown output

5. **Verify Output**:
   - Confirm file was created
   - Show statistics (message count, mode, file location)
   - Offer to show preview or make adjustments

### Example Interaction

**User**: "Export this conversation to markdown"

**Assistant**: "I'll help you export this conversation. Which export mode would you like?"

*Present options using AskUserQuestion:*
- **Minimal** (仅对话) - Only conversation content, clean and readable
- **Standard** (含工具调用) - Conversation + tool calls (files, commands)
- **Detailed** (完整详细) - Complete record with tool outputs and diffs

**User**: Selects "Minimal"

**Assistant**: Exports using: `python3 scripts/export-conversation.py <file> output.md minimal`

**Result**: "✅ Exported 660 messages to conversation-export-minimal.md"

---

## Related Skills

- **doc-coauthoring**: For structured document creation workflows
- **skill-creator**: For creating your own custom skills
- **internal-comms**: For formatting team communications

---

**Enjoy preserving your valuable conversations!** 📝
