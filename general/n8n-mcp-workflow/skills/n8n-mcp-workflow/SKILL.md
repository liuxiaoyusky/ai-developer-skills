---
name: n8n-mcp-workflow
description: Use when developing MCP servers for n8n, creating n8n workflows programmatically, integrating n8n with Model Context Protocol, or automating n8n workflow deployment. Covers n8n API, workflow structure, node configuration, and common automation patterns.
---

# n8n MCP & Workflow Automation

Expert guidance for developing MCP servers to interact with n8n and creating n8n workflows programmatically.

---

## Overview

**What is this?**
Comprehensive guide for building Model Context Protocol (MCP) servers that interact with n8n, and for programmatically creating and managing n8n workflows.

**Core principle:**
n8n workflows are JSON structures that define nodes, connections, and execution flow. Understanding this structure enables programmatic workflow creation and automation.

**Use cases:**
- Build MCP servers that trigger n8n workflows
- Create n8n workflows dynamically via API
- Automate workflow deployment and management
- Integrate n8n with AI agents and Claude Code

---

## Quick Start

### Basic n8n Workflow Structure

Every n8n workflow is a JSON object with three main components:

```json
{
  "name": "My Workflow",
  "nodes": [
    {
      "parameters": {},
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "position": [250, 300]
    },
    {
      "parameters": {},
      "name": "HTTP Request",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [450, 300]
    }
  ],
  "connections": {
    "Webhook": {
      "main": [
        [
          {
            "node": "HTTP Request",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
```

### Essential Rules

1. **Every node needs**: `name`, `type`, `typeVersion`, `position`, `parameters`
2. **Connections define flow**: Link output of one node to input of another
3. **Node types**: Use `n8n-nodes-base.{nodeName}` format
4. **Position coordinates**: `[x, y]` in pixels for visual layout
5. **CRITICAL**: Self-hosted n8n instance required for API access (not available on n8n cloud)

---

## Mode Selection Guide

### API vs UI: When to Use Each

### n8n API (Programmatic)

**Use this mode for:**
- **Automated workflow deployment**: CI/CD pipelines for workflows
- **Dynamic workflow creation**: Generate workflows based on templates
- **Bulk operations**: Update multiple workflows at once
- **Integration with external systems**: Connect with AI agents, custom apps
- **Workflow version control**: Track and manage workflow changes

**Limitations:**
- Requires self-hosted n8n instance
- API access needs authentication setup
- Workflow UI validation bypassed (test thoroughly!)

### n8n UI (Browser)

**Use this mode for:**
- **Rapid prototyping**: Visual workflow design
- **Complex configurations**: Node parameters with UI helpers
- **Testing and debugging**: Interactive execution and inspection
- **Learning**: Understanding node capabilities and connections

```bash
# API requires self-hosted instance with credentials
N8N_HOST="https://your-n8n-instance.com"
N8N_API_KEY="your-api-key"

# UI works with both self-hosted and cloud
# Just open https://your-n8n-instance.com in browser
```

---

## MCP Server for n8n

### MCP Server Template

Create MCP servers to expose n8n capabilities to Claude Code and AI agents.

```typescript
// n8n-mcp-server/src/index.ts
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

const N8N_API_URL = process.env.N8N_API_URL || 'http://localhost:5678/api';
const N8N_API_KEY = process.env.N8N_API_KEY;

// MCP Server setup
const server = new Server(
  {
    name: 'n8n-mcp-server',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'trigger_workflow',
        description: 'Trigger an n8n workflow by ID or name',
        inputSchema: {
          type: 'object',
          properties: {
            workflowId: {
              type: 'string',
              description: 'Workflow ID or name to trigger',
            },
            data: {
              type: 'object',
              description: 'Data to pass to workflow',
            },
          },
          required: ['workflowId'],
        },
      },
      {
        name: 'create_workflow',
        description: 'Create a new n8n workflow programmatically',
        inputSchema: {
          type: 'object',
          properties: {
            workflow: {
              type: 'object',
              description: 'Workflow JSON object',
            },
          },
          required: ['workflow'],
        },
      },
      {
        name: 'list_workflows',
        description: 'List all n8n workflows',
        inputSchema: {
          type: 'object',
          properties: {},
        },
      },
      {
        name: 'get_workflow',
        description: 'Get a specific workflow by ID',
        inputSchema: {
          type: 'object',
          properties: {
            workflowId: {
              type: 'string',
              description: 'Workflow ID',
            },
          },
          required: ['workflowId'],
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'trigger_workflow': {
        const response = await fetch(
          `${N8N_API_URL}/workflows/${args.workflowId}/execute`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-N8N-API-KEY': N8N_API_KEY!,
            },
            body: JSON.stringify({ data: args.data }),
          }
        );
        const result = await response.json();
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'create_workflow': {
        const response = await fetch(`${N8N_API_URL}/workflows`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-N8N-API-KEY': N8N_API_KEY!,
          },
          body: JSON.stringify(args.workflow),
        });
        const result = await response.json();
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'list_workflows': {
        const response = await fetch(`${N8N_API_URL}/workflows`, {
          headers: {
            'X-N8N-API-KEY': N8N_API_KEY!,
          },
        });
        const result = await response.json();
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'get_workflow': {
        const response = await fetch(
          `${N8N_API_URL}/workflows/${args.workflowId}`,
          {
            headers: {
              'X-N8N-API-KEY': N8N_API_KEY!,
            },
          }
        );
        const result = await response.json();
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({ error: String(error) }, null, 2),
        },
      ],
      isError: true,
    };
  }
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('n8n MCP server running on stdio');
}

main().catch(console.error);
```

### MCP Server Package.json

```json
{
  "name": "n8n-mcp-server",
  "version": "1.0.0",
  "type": "module",
  "description": "MCP server for n8n workflow automation",
  "main": "build/index.js",
  "scripts": {
    "build": "tsc",
    "start": "node build/index.js",
    "dev": "tsc && node build/index.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.4",
    "node-fetch": "^3.3.2"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0"
  }
}
```

---

## Common Node Types

### Most Used Nodes Reference

```json
{
  "nodes": [
    {
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 2,
      "position": [250, 300],
      "parameters": {
        "path": "webhook",
        "responseMode": "responseNode",
        "options": {}
      }
    },
    {
      "name": "HTTP Request",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.2,
      "position": [450, 300],
      "parameters": {
        "url": "https://api.example.com/endpoint",
        "method": "GET",
        "sendHeaders": true,
        "headerParameters": {
          "parameters": [
            {
              "name": "Authorization",
              "value": "Bearer {{ $env.API_KEY }}"
            }
          ]
        }
      }
    },
    {
      "name": "Code",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [650, 300],
      "parameters": {
        "language": "javaScript",
        "jsCode": "// Your JavaScript code here\nreturn items.map(item => {\n  return {\n    json: {\n      ...item.json,\n      processed: true\n    }\n  }\n});"
      }
    },
    {
      "name": "Set",
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.4,
      "position": [850, 300],
      "parameters": {
        "values": {
          "string": [
            {
              "name": "newField",
              "value": "={{ $json.field }}"
            }
          ]
        }
      }
    },
    {
      "name": "IF",
      "type": "n8n-nodes-base.if",
      "typeVersion": 2.1,
      "position": [1050, 300],
      "parameters": {
        "conditions": {
          "string": [
            {
              "value1": "={{ $json.status }}",
              "operation": "equals",
              "value2": "active"
            }
          ]
        }
      }
    }
  ]
}
```

**See**: [NODE_REFERENCE.md](NODE_REFERENCE.md) for complete node type catalog

---

## Connection Patterns

### Pattern 1: Linear Flow (Most Common)

```json
{
  "connections": {
    "Webhook": {
      "main": [
        [
          {
            "node": "HTTP Request",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "HTTP Request": {
      "main": [
        [
          {
            "node": "Code",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Code": {
      "main": [
        [
          {
            "node": "Set",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
```

### Pattern 2: Conditional Branching (IF Node)

```json
{
  "connections": {
    "IF": {
      "main": [
        [
          {
            "node": "Process Success",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "Handle Error",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
```

**Note**: First array = true branch, second array = false branch

### Pattern 3: Multiple Outputs (Split)

```json
{
  "connections": {
    "Process Data": {
      "main": [
        [
          {
            "node": "Send Email",
            "type": "main",
            "index": 0
          },
          {
            "node": "Update Database",
            "type": "main",
            "index": 0
          },
          {
            "node": "Log Activity",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
```

**See**: [CONNECTION_PATTERNS.md](CONNECTION_PATTERNS.md) for advanced patterns

---

## Workflow Creation Patterns

### Pattern 1: Webhook Trigger → Process → Respond

```javascript
// Create webhook-driven workflow
const workflow = {
  name: "Webhook Processor",
  nodes: [
    {
      name: "Webhook",
      type: "n8n-nodes-base.webhook",
      typeVersion: 2,
      position: [250, 300],
      parameters: {
        path: "process",
        responseMode: "responseNode",
        options: {}
      }
    },
    {
      name: "Process Data",
      type: "n8n-nodes-base.code",
      typeVersion: 2,
      position: [450, 300],
      parameters: {
        language: "javaScript",
        jsCode: `const data = items[0].json;
const result = {
  processed: true,
  timestamp: new Date().toISOString(),
  input: data
};
return [{ json: result }];`
      }
    },
    {
      name: "Respond to Webhook",
      type: "n8n-nodes-base.respondToWebhook",
      typeVersion: 1.1,
      position: [650, 300],
      parameters: {
        "respondWith": "json",
        "responseBody": "={{ JSON.stringify($json) }}"
      }
    }
  ],
  connections: {
    "Webhook": {
      "main": [[{ "node": "Process Data", "type": "main", "index": 0 }]]
    },
    "Process Data": {
      "main": [[{ "node": "Respond to Webhook", "type": "main", "index": 0 }]]
    }
  }
};

// Create via MCP tool
await mcpClient.callTool({
  name: "create_workflow",
  arguments: { workflow }
});
```

### Pattern 2: Scheduled Task → Process → Notify

```javascript
const scheduledWorkflow = {
  name: "Daily Report Generator",
  nodes: [
    {
      name: "Schedule Trigger",
      type: "n8n-nodes-base.scheduleTrigger",
      typeVersion: 1.2,
      position: [250, 300],
      parameters: {
        rule: {
          interval: [{ "field": "cronExpression", "expression": "0 9 * * *" }]
        }
      }
    },
    {
      name: "HTTP Request",
      type: "n8n-nodes-base.httpRequest",
      typeVersion: 4.2,
      position: [450, 300],
      parameters: {
        url: "https://api.example.com/report",
        method: "GET"
      }
    },
    {
      name: "Send Email",
      type: "n8n-nodes-base.emailSend",
      typeVersion: 2.1,
      position: [650, 300],
      parameters: {
        fromEmail: "reports@company.com",
        toEmail: "team@company.com",
        subject: "Daily Report",
        emailType: "html",
        message: "={{ JSON.stringify($json) }}"
      }
    }
  ],
  connections: {
    "Schedule Trigger": {
      "main": [[{ "node": "HTTP Request", "type": "main", "index": 0 }]]
    },
    "HTTP Request": {
      "main": [[{ "node": "Send Email", "type": "main", "index": 0 }]]
    }
  }
};
```

### Pattern 3: Error Handling with IF Node

```javascript
const errorHandlingWorkflow = {
  name: "API Handler with Error Management",
  nodes: [
    {
      name: "Webhook",
      type: "n8n-nodes-base.webhook",
      typeVersion: 2,
      position: [250, 300],
      parameters: { path: "api-handler" }
    },
    {
      name: "Call API",
      type: "n8n-nodes-base.httpRequest",
      typeVersion: 4.2,
      position: [450, 300],
      parameters: {
        url: "https://api.example.com/endpoint",
        method: "POST"
      }
    },
    {
      name: "Check Success",
      type: "n8n-nodes-base.if",
      typeVersion: 2.1,
      position: [650, 300],
      parameters: {
        conditions: {
          number: [
            {
              "value1": "={{ $json.statusCode }}",
              "operation": "smaller",
              "value2": 400
            }
          ]
        }
      }
    },
    {
      name: "Handle Success",
      type: "n8n-nodes-base.code",
      typeVersion: 2,
      position: [850, 200],
      parameters: {
        language: "javaScript",
        jsCode: "return [{ json: { status: 'success', data: $json } }];"
      }
    },
    {
      name: "Handle Error",
      type: "n8n-nodes-base.code",
      typeVersion: 2,
      position: [850, 400],
      parameters: {
        language: "javaScript",
        jsCode: "return [{ json: { status: 'error', message: $json.error } }];"
      }
    }
  ],
  connections: {
    "Webhook": {
      "main": [[{ "node": "Call API", "type": "main", "index": 0 }]]
    },
    "Call API": {
      "main": [[{ "node": "Check Success", "type": "main", "index": 0 }]]
    },
    "Check Success": {
      "main": [
        [{ "node": "Handle Success", "type": "main", "index": 0 }],
        [{ "node": "Handle Error", "type": "main", "index": 0 }]
      ]
    }
  }
};
```

**See**: [WORKFLOW_PATTERNS.md](WORKFLOW_PATTERNS.md) for 20+ production-ready patterns

---

## Critical: Authentication Setup

### n8n API Key Configuration

**CRITICAL REQUIREMENT**: Self-hosted n8n instance required

```bash
# Set environment variables for n8n
export N8N_BASIC_AUTH_ACTIVE=true
export N8N_BASIC_AUTH_USER=admin
export N8N_BASIC_AUTH_PASSWORD=your-password

# Enable API access
export N8N_API_ENABLED=true

# Start n8n
n8n start
```

### Generate API Key via UI

1. Open n8n web interface
2. Go to **Settings** → **API**
3. Click **Create API Key**
4. Copy and store securely (shown only once!)

### Use API Key in Requests

```bash
# Trigger workflow
curl -X POST \
  https://your-n8n.com/api/workflows/{workflowId}/execute \
  -H 'X-N8N-API-KEY: your-api-key' \
  -H 'Content-Type: application/json' \
  -d '{"data": {"key": "value"}}'

# Create workflow
curl -X POST \
  https://your-n8n.com/api/workflows \
  -H 'X-N8N-API-KEY: your-api-key' \
  -H 'Content-Type: application/json' \
  -d @workflow.json

# List workflows
curl https://your-n8n.com/api/workflows \
  -H 'X-N8N-API-KEY: your-api-key'
```

**See**: [AUTHENTICATION.md](AUTHENTICATION.md) for comprehensive security setup

---

## Common Patterns Overview

Based on production workflows, here are the most useful patterns:

### 1. Webhook → Transform → External API

```javascript
{
  "name": "Sync to External System",
  "nodes": [
    webhookNode,
    transformNode,
    httpRequestNode
  ]
}
```

### 2. Scheduled → Aggregate → Email Report

```javascript
{
  "name": "Daily Summary",
  "nodes": [
    scheduleNode,
    aggregationNode,
    emailNode
  ]
}
```

### 3. Manual Trigger → Multi-step Process → Notification

```javascript
{
  "name": "Complex Pipeline",
  "nodes": [
    manualTrigger,
    step1Node,
    step2Node,
    step3Node,
    slackNotification
  ]
}
```

### 4. Event Stream → Filter → Branch → Merge

```javascript
{
  "name": "Event Processor",
  "nodes": [
    webhookNode,
    filterNode,
    ifNode,
    processBranchA,
    processBranchB,
    mergeNode
  ]
}
```

### 5. API Chain → Error Handling → Retry Logic

```javascript
{
  "name": "Resilient API Client",
  "nodes": [
    triggerNode,
    apiCallNode,
    ifErrorNode,
    waitNode,
    retryNode,
    successNode
  ]
}
```

---

## Error Prevention - Top 5 Mistakes

### #1: Invalid Node Type Format

```javascript
// ❌ WRONG: Missing prefix
"type": "webhook"

// ❌ WRONG: Wrong prefix
"type": "node.webhook"

// ✅ CORRECT: Full node type
"type": "n8n-nodes-base.webhook"

// ✅ CORRECT: Custom node format
"type": "n8n-nodes-base.customNode"
```

### #2: Missing Connection Object

```javascript
// ❌ WRONG: No connections defined
{
  "name": "My Workflow",
  "nodes": [...]
  // Missing "connections"!
}

// ✅ CORRECT: Include connections
{
  "name": "My Workflow",
  "nodes": [...],
  "connections": {
    "Node1": {
      "main": [[{ "node": "Node2", "type": "main", "index": 0 }]]
    }
  }
}
```

### #3: Wrong TypeVersion

```javascript
// ❌ WRONG: Guessing version number
"typeVersion": 999

// ✅ CORRECT: Check node's actual version
// 1. Create node in UI
// 2. Export workflow
// 3. Copy exact typeVersion
"typeVersion": 2.1
```

### #4: Position Overlap (Visual Chaos)

```javascript
// ❌ WRONG: Nodes on top of each other
{ "position": [250, 300] },
{ "position": [250, 300] }  // Same position!

// ✅ CORRECT: Space nodes out properly
{ "position": [250, 300] },
{ "position": [450, 300] },
{ "position": [650, 300] }
```

### #5: Forgetting ResponseNode for Webhooks

```javascript
// ❌ WRONG: Webhook expects response but none provided
{
  "type": "n8n-nodes-base.webhook",
  "parameters": {
    "path": "webhook",
    "responseMode": "responseNode"  // Needs response node!
  }
  // Missing respondToWebhook node
}

// ✅ CORRECT: Add response node
{
  "nodes": [
    webhookNode,
    respondToWebhookNode  // Required!
  ],
  "connections": {
    "Webhook": {
      "main": [[{ "node": "Respond to Webhook" }]]
    }
  }
}
```

**See**: [ERROR_PATTERNS.md](ERROR_PATTERNS.md) for comprehensive error guide

---

## Workflow JSON Structure Deep Dive

### Complete Workflow Object

```javascript
{
  "id": "workflow-uuid-here",
  "name": "Complete Workflow Example",
  "active": false,
  "nodes": [...],
  "connections": {...},
  "settings": {
    "executionOrder": "v1"
  },
  "staticData": null,
  "tags": [],
  "pinData": {},
  "meta": {
    "templateCredsSetupCompleted": false,
    "instanceId": "instance-uuid"
  }
}
```

### Node Object Structure

```javascript
{
  "parameters": {
    // Node-specific configuration
    // Varies by node type
  },
  "id": "node-uuid-here",
  "name": "Display Name",
  "type": "n8n-nodes-base.nodeType",
  "typeVersion": 1.0,
  "position": [x, y],
  "webhookId": "webhook-uuid",  // Webhook nodes only
  "retryOnFail": true,
  "maxTries": 3,
  "waitBetweenTries": 1000,
  "continueOnFail": false,
  "alwaysOutputData": false
}
```

### Connection Object Structure

```javascript
{
  "SourceNodeName": {
    "main": [
      [  // First output branch
        {
          "node": "TargetNodeName",
          "type": "main",
          "index": 0
        }
      ]
    ],
    "aiAgent": [  // AI Agent nodes have multiple output types
      [
        {
          "node": "AgentHandler",
          "type": "aiAgent",
          "index": 0
        }
      ]
    ]
  }
}
```

**See**: [WORKFLOW_STRUCTURE.md](WORKFLOW_STRUCTURE.md) for complete schema reference

---

## Best Practices

### 1. Always Test in UI First

```javascript
// ✅ GOOD: Create in UI, export JSON, then automate
// 1. Build workflow manually in n8n UI
// 2. Test execution thoroughly
// 3. Export workflow JSON
// 4. Use as template for programmatic creation

// ❌ RISKY: Write JSON from scratch without testing
// Easy to miss required parameters or wrong typeVersions
```

### 2. Use Descriptive Node Names

```javascript
// ✅ GOOD: Clear, descriptive names
{ "name": "Fetch User Data" },
{ "name": "Transform to Internal Format" },
{ "name": "Update CRM System" }

// ❌ BAD: Generic names
{ "name": "HTTP Request 1" },
{ "name": "Code 2" },
{ "name": "Set 3" }
```

### 3. Organize Nodes Visually

```javascript
// ✅ GOOD: Logical flow, spaced out
{ "position": [250, 300] },   // Trigger
{ "position": [450, 300] },   // Process
{ "position": [650, 300] },   // Transform
{ "position": [850, 200] },   // Branch A (success)
{ "position": [850, 400] },   // Branch B (error)

// ❌ BAD: Random positions
{ "position": [123, 456] },
{ "position": [789, 12] },
```

### 4. Version Control Workflows

```bash
# ✅ GOOD: Track workflow JSON in git
git add workflows/*.json
git commit -m "Add user sync workflow"

# ✅ GOOD: Use environment-specific configs
workflows/
  production/
    user-sync.json
  staging/
    user-sync.json
```

### 5. Handle Errors Gracefully

```javascript
// ✅ GOOD: Continue on fail for non-critical nodes
{
  "name": "Log to Analytics",
  "continueOnFail": true,
  "parameters": {...}
}

// ✅ GOOD: Explicit error handling
{
  "name": "Check API Success",
  "type": "n8n-nodes-base.if",
  "parameters": {
    "conditions": {
      "number": [{
        "operation": "smaller",
        "value1": "={{ $json.statusCode }}",
        "value2": 400
      }]
    }
  }
}
```

---

## Integration with Other Skills

### Works With:

**n8n-code-python**:
- Write Python code in Code nodes
- When to use Python vs JavaScript
- Data access patterns in Python

**n8n-code-javascript**:
- JavaScript code examples for Code nodes
- Helper functions and utilities
- Common JavaScript patterns

**mcp-builder**:
- Build MCP servers for other services
- Combine n8n with other MCP integrations
- Best practices for MCP development

**Claude Code Automation**:
- Create hooks to trigger n8n workflows
- Use n8n as part of development workflows
- Automate deployment processes

---

## Quick Reference Checklist

Before deploying workflows programmatically, verify:

- [ ] **Self-hosted n8n** - API access requires self-hosted instance
- [ ] **Valid API key** - Generated and properly configured
- [ ] **Tested in UI** - Workflow works manually first
- [ ] **Valid node types** - Using `n8n-nodes-base.{name}` format
- [ ] **Correct typeVersion** - Matches node's actual version
- [ ] **All connections defined** - Every node properly connected
- [ ] **Unique node names** - No duplicates
- [ ] **Proper spacing** - Visual layout is clean
- [ ] **Error handling** - Failures handled appropriately
- [ ] **Environment variables** - Sensitive data in env vars, not hardcoded

---

## Additional Resources

### Related Files
- [NODE_REFERENCE.md](NODE_REFERENCE.md) - Complete node type catalog
- [CONNECTION_PATTERNS.md](CONNECTION_PATTERNS.md) - Advanced connection patterns
- [WORKFLOW_PATTERNS.md](WORKFLOW_PATTERNS.md) - 20+ production-ready workflows
- [ERROR_PATTERNS.md](ERROR_PATTERNS.md) - Top errors and solutions
- [AUTHENTICATION.md](AUTHENTICATION.md) - Security and API setup
- [WORKFLOW_STRUCTURE.md](WORKFLOW_STRUCTURE.md) - Complete JSON schema

### External Resources
- n8n API Documentation: https://docs.n8n.io/api/
- n8n Workflow Reference: https://docs.n8n.io/workflows/workflows/
- n8n Community: https://community.n8n.io/
- MCP Protocol Spec: https://modelcontextprotocol.io/

### Learning Resources
- [Create Dynamic Workflows Programmatically](https://n8n.io/workflows/4544-create-dynamic-workflows-programmatically-via-webhooks-and-n8n-api/) (May 31, 2025)
- [Automate creation of n8n workflows via Agents](https://community.n8n.io/t/automate-creation-of-n8n-workflows-via-agents/118650) (May 21, 2025)
- [n8n workflow manager API](https://n8n.io/workflows/4166-n8n-workflow-manager-api/)
- [Anyone using the n8n API to build flows programmatically](https://www.reddit.com/r/n8n/comments/1kiq97r/anyone_using_the_n8n_api_to_build_flows/)

---

**Ready to build MCP servers for n8n and create workflows programmatically!** Start with simple workflows, test thoroughly in the UI before automating, and leverage the pattern library for common automation scenarios.

**Sources:**
- [Create Dynamic Workflows Programmatically](https://n8n.io/workflows/4544-create-dynamic-workflows-programmatically-via-webhooks-and-n8n-api/)
- [Automate creation of n8n workflows via Agents](https://community.n8n.io/t/automate-creation-of-n8n-workflows-via-agents/118650)
- [n8n workflow manager API](https://n8n.io/workflows/4166-n8n-workflow-manager-api/)
- [Anyone using the n8n API to build flows programmatically](https://www.reddit.com/r/n8n/comments/1kiq97r/anyone_using_the_n8n_api_to_build_flows/)
