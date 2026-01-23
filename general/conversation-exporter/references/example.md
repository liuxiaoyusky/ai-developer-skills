# Conversation Exporter - Usage Examples

This document provides practical examples of using the conversation-exporter skill.

---

## Example 1: Minimal Export (Quick Reference)

### Scenario
You just finished debugging an issue and want a clean record of what was discussed.

### Command
```
Export this conversation to markdown
```

### Output File
`conversation-export_20260123.md`

### Sample Output

```markdown
# Conversation Export

**Generated**: 2026-01-23 15:30:45
**Mode**: minimal
**Messages**: 42

---

## 👤 User - 2026-01-23 09:45:34

How do I fix the CORS error in my API? I'm getting:
"Access to fetch at 'https://api.example.com' from origin 'https://example.com' has been blocked by CORS policy"

## 🤖 Assistant - 2026-01-23 09:46:12

I'll help you fix the CORS error. Let me check your current API configuration first.

---

## 👤 User - 2026-01-23 09:48:20

The API is hosted on Azure Functions. Do I need to configure CORS there or in my code?

## 🤖 Assistant - 2026-01-23 09:49:05

For Azure Functions, you have two options:

1. **Platform-level CORS** (recommended): Configure in Azure Portal or via Azure CLI
2. **Code-level CORS**: Add CORS headers in your function code

Platform-level is easier and more maintainable. Here's how to do it via Azure CLI:

```bash
az functionapp cors add \
  --name your-function-app \
  --resource-group your-resource-group \
  --allowed-origins "https://your-frontend.com"
```

---

## 👤 User - 2026-01-23 09:52:40

That worked! Thanks for the help.

## 🤖 Assistant - 2026-01-23 09:53:15

Great! The CORS configuration is now working. Your frontend can now make requests to your Azure Functions backend without being blocked by the browser.

---
```

---

## Example 2: Standard Export (Technical Documentation)

### Scenario
You want to document a debugging session for your team, including which files were checked and what commands were run.

### Command
```
Export this conversation in standard mode to cors-debugging-guide.md
```

### Output File
`cors-debugging-guide.md`

### Sample Output

```markdown
# Conversation Export

**Generated**: 2026-01-23 15:30:45
**Mode**: standard
**Messages**: 42

---

## 👤 User - 2026-01-23 10:15:22

I'm getting CORS errors when trying to access the API from my frontend. The error says no 'Access-Control-Allow-Origin' header is present.

## 🤖 Assistant - 2026-01-23 10:16:45

The CORS configuration needs to be updated. Let me check the current headers your API is returning.

**Tool Calls**:
- **Bash**
    - command: curl -I https://your-api.azurewebsites.net/api/health

---

## 👤 User - 2026-01-23 10:18:30

The curl output doesn't show any CORS headers. Should I add them in my code?

## 🤖 Assistant - 2026-01-23 10:19:15

You can add them in code, but it's better to configure at the platform level. Let me check your current function configuration.

**Tool Calls**:
- **Read**
    - file_path: /azure-functions/src/index.js
    - limit: 50

---

## 👤 User - 2026-01-23 10:22:10

I see the CORS headers are being set in the code. Why aren't they working?

## 🤖 Assistant - 2026-01-23 10:23:45

Let me check if there's a platform-level CORS configuration that might be overriding your code settings.

**Tool Calls**:
- **Bash**
    - command: az functionapp cors list --name your-api --resource-group your-rg

The platform CORS is empty. Let's add your origin:

**Tool Calls**:
- **Bash**
    - command: az functionapp cors add --name your-api --resource-group your-rg --allowed-origins "https://your-frontend.com"

---
```

---

## Example 3: Detailed Export (Complete Record)

### Scenario
You need a complete forensic record of a complex debugging session, including all tool outputs, error messages, and code changes.

### Command
```
Export this conversation in detailed mode to complete-debugging-record.md
```

### Output File
`complete-debugging-record.md`

### Sample Output

```markdown
# Conversation Export

**Generated**: 2026-01-23 15:30:45
**Mode**: detailed
**Messages**: 42

---

## 👤 User - 2026-01-23 10:15:22

I'm getting CORS errors when trying to access the API from my frontend.

## 🤖 Assistant - 2026-01-23 10:16:45

Let me check what headers your API is currently returning.

**Tool Calls**:
- **Bash**
    - command: curl -I https://your-api.azurewebsites.net/api/health

**Result**:
HTTP/2 200
content-type: application/json
date: Thu, 23 Jan 2026 10:16:50 GMT

Note: No CORS headers present

---

## 👤 User - 2026-01-23 10:18:30

The API isn't returning CORS headers. Should I add them in my code?

## 🤖 Assistant - 2026-01-23 10:19:15

Let me check your current API code to see if CORS is configured there.

**Tool Calls**:
- **Read**
    - file_path: /azure-functions/src/index.js
    - offset: 20
    - limit: 30

**Result**:
```javascript
function getCorsHeaders(request) {
  const origin = request.headers.get('origin');

  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };
}
```

The code looks correct. Let me check if it's being used properly...

---

## 👤 User - 2026-01-23 10:25:10

Wait, I think I found the issue. The function name is wrong in the import!

## 🤖 Assistant - 2026-01-23 10:26:30

Great catch! Let me check the import statement.

**Tool Calls**:
- **Read**
    - file_path: /azure-functions/src/index.js
    - offset: 0
    - limit: 20

**Result**:
```javascript
const { handleStep1, handleStep2Stream, handleStep3Stream } = require('./interpret-steps');
```

Found it! The import says `handleStep1` but it should be `handleStep1Stream`. Let me fix that.

**Tool Calls**:
- **Edit**
    - file_path: /azure-functions/src/index.js
    - old_string: const { handleStep1, handleStep2Stream, handleStep3Stream } = require('./interpret-steps');
    - new_string: const { handleStep1Stream, handleStep2Stream, handleStep3Stream } = require('./interpret-steps');

**Result**:
File edited successfully

And update the function call:

**Tool Calls**:
- **Edit**
    - file_path: /azure-functions/src/index.js
    - old_string: return handleStep1(request, user, clientIP, corsHeaders);
    - new_string: return handleStep1Stream(request, user, clientIP, corsHeaders);

**Result**:
File edited successfully

Now let's deploy the fix:

**Tool Calls**:
- **Bash**
    - command: cd azure-functions && npm run deploy

**Result**:
Deploying to volaris-api-flex...
Successfully deployed 24 functions

✅ Fix deployed!

---
```

---

## Quick Reference

### Export Modes Summary

| Mode | Includes | Best For |
|------|----------|----------|
| **minimal** | User + Assistant text only | Quick reference, sharing, clean reading |
| **standard** | minimal + Tool calls (which commands/tools were used) | Technical docs, debugging guides, tutorials |
| **detailed** | standard + Tool outputs, code diffs, errors | Complete records, forensic analysis, comprehensive docs |

### Common Commands

```
# Simple export (minimal mode, default filename)
Export this conversation to markdown

# Custom filename
Export this conversation to bug-fix-summary.md

# Standard mode
Export this conversation in standard mode

# Detailed mode with custom filename
Export this conversation in detailed mode to full-record.md

# Export specific conversation file
Export ~/.claude/projects/.../session.jsonl to output.md

# Export specific file in detailed mode
Export ~/.claude/projects/.../session.jsonl to complete-doc.md in detailed mode
```

---

## Tips

1. **Use minimal mode** for sharing with non-technical team members
2. **Use standard mode** for creating debugging guides and tutorials
3. **Use detailed mode** for comprehensive documentation and audit trails
4. **Export regularly** after important discussions or bug fixes
5. **Organize exports** in a dedicated folder for easy reference

---

Happy exporting! 📝
