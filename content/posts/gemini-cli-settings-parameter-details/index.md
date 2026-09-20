---
title: "GEMINI-CLI Settings Parameter Details"
date: 2025-12-09T10:00:00+00:00
draft: false
tags: ["Gemini CLI", "Configuration", "AI Agent", "LLM", "A2A-Server", "DevTools"]
categories: ["AI & LLM", "Tools"]
summary: "In-depth analysis of Gemini CLI core configuration parameters, covering key modules such as Checkpointing, Model Aliases, Context, and Tools. This article details the differences in parameter support between CLI mode and A2A-Server mode, helping developers accurately configure and optimize AI Agent workflows."
showSummary: true
---

In-depth analysis of Gemini CLI core configuration parameters, covering key modules such as Checkpointing, Model Aliases, Context, and Tools. This article details the differences in parameter support between CLI mode and A2A-Server mode, helping developers accurately configure and optimize AI Agent workflows.

## Overview

Gemini CLI provides a unified command line interface for interacting with advanced agentic language models. When developing workflows that combine command line scripts and background agent processes, understanding parameter resolution is critical.

### Key Parameter Groups

1. **Checkpointing**: Controls state persistence across sessions and branch workspaces.
2. **Model Aliases**: Maps friendly aliases to specific upstream model deployments.
3. **Context Window Management**: Configures chunk sizes, sliding memory buffers, and truncation strategies.
4. **Tools & Capabilities**: Declares system-level tool definitions, environment sandboxes, and file system permissions.

```bash
# Example invocation with checkpointing enabled
gemini-cli agent run --model gemini-2.5-pro --checkpoint auto --tools bash,file-editor
```

### Differences: CLI vs A2A-Server Mode

| Parameter | CLI Mode | A2A-Server Mode |
|---|---|---|
| `--session-id` | Auto-generated | Provided via handshake |
| `--persistent` | Process lifetime | Daemon lifetime |
| `--tools` | Local process shell | Sandbox worker |

Optimizing these settings ensures low latency and robust multi-step agent execution.
