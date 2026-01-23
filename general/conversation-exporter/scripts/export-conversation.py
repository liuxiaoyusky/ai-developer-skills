#!/usr/bin/env python3
"""
Export Claude Code conversation history to markdown format.

This script reads Claude Code conversation .jsonl files and exports them
to clean, readable markdown format with configurable detail levels.

Usage:
    python export-conversation.py <jsonl-file> [output-file] [mode]

Arguments:
    jsonl-file: Path to conversation .jsonl file
    output-file: Optional output path (default: conversation-export_YYYYMMDD.md)
    mode: Export mode - minimal, standard, or detailed (default: minimal)

Modes:
    minimal: User and assistant messages only
    standard: Everything in minimal + tool calls
    detailed: Everything in standard + tool outputs and code diffs
"""

import json
import sys
from pathlib import Path
from datetime import datetime


def parse_jsonl(filepath):
    """Parse JSONL conversation file and extract relevant messages."""
    messages = []

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue

                try:
                    obj = json.loads(line)

                    # Extract user and assistant messages
                    if obj.get('type') in ['user', 'assistant']:
                        messages.append(obj)

                    # In detailed mode, also include file-history-snapshot
                    if obj.get('type') == 'file-history-snapshot':
                        # Only include if we're tracking tool results
                        messages.append(obj)

                except json.JSONDecodeError as e:
                    print(f"Warning: Failed to parse line {line_num}: {e}", file=sys.stderr)
                    continue

    except FileNotFoundError:
        print(f"Error: File not found: {filepath}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: Failed to read file: {e}", file=sys.stderr)
        sys.exit(1)

    return messages


def extract_text_content(content_array):
    """Extract text from content array structure."""
    if not isinstance(content_array, list):
        return ""

    texts = []
    for item in content_array:
        if isinstance(item, dict) and item.get('type') == 'text':
            text = item.get('text', '')
            texts.append(text)

    return '\n'.join(texts)


def extract_tool_calls(content_array):
    """Extract tool calls from content array."""
    if not isinstance(content_array, list):
        return []

    tool_calls = []

    for item in content_array:
        if isinstance(item, dict):
            # Check for tool_use items
            if item.get('type') == 'tool_use':
                tool_calls.append({
                    'id': item.get('id', ''),
                    'name': item.get('name', ''),
                    'input': item.get('input', {})
                })
            # Check for tool_result items
            elif item.get('type') == 'tool_result':
                tool_calls.append({
                    'type': 'tool_result',
                    'tool_use_id': item.get('tool_use_id', ''),
                    'content': extract_text_content(item.get('content', []))
                })

    return tool_calls


def format_timestamp(timestamp_str):
    """Format ISO timestamp to readable format."""
    try:
        # Handle UTC timestamp
        dt = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
        return dt.strftime('%Y-%m-%d %H:%M:%S')
    except:
        return timestamp_str


def format_tool_input(tool_input):
    """Format tool input parameters for display."""
    if not isinstance(tool_input, dict):
        return str(tool_input)

    parts = []
    for key, value in tool_input.items():
        if key == 'internal':
            continue  # Skip internal metadata

        # Format different types of values
        if isinstance(value, str):
            if len(value) > 100:
                value = value[:97] + '...'
            parts.append(f"{key}: {value}")
        elif isinstance(value, list):
            parts.append(f"{key}: [{len(value)} items]")
        elif isinstance(value, dict):
            parts.append(f"{key}: {{...}}")
        else:
            parts.append(f"{key}: {value}")

    return '\n    '.join(parts) if parts else ''


def format_code_diff(content):
    """Format code diffs with proper markdown."""
    # This is a simplified version - real implementation would parse actual diffs
    lines = content.split('\n')
    formatted_lines = []

    for line in lines:
        if line.startswith('+') and not line.startswith('+++'):
            formatted_lines.append(f"<span style='color:green'>{line}</span>")
        elif line.startswith('-') and not line.startswith('---'):
            formatted_lines.append(f"<span style='color:red'>{line}</span>")
        else:
            formatted_lines.append(line)

    return '\n'.join(formatted_lines)


def to_markdown(messages, mode='minimal'):
    """Convert messages to markdown format."""
    output = []

    # Header
    output.append("# Conversation Export\n")
    output.append(f"**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    output.append(f"**Mode**: {mode}")
    output.append(f"**Messages**: {len(messages)}")
    output.append("\n---\n")

    for msg in messages:
        msg_type = msg.get('type', '')
        timestamp = format_timestamp(msg.get('timestamp', ''))

        # Handle file-history-snapshot differently
        if msg_type == 'file-history-snapshot':
            if mode == 'detailed':
                output.append(f"## 📁 File Change - {timestamp}\n")
                # Could include diff details here
                output.append("*File history snapshot recorded*\n")
            continue

        # Regular user/assistant messages
        message = msg.get('message', {})
        role = message.get('role', 'unknown').title()
        content_array = message.get('content', [])

        # Extract main text content
        text_content = extract_text_content(content_array)

        # Skip messages with no text content
        if not text_content or not text_content.strip():
            continue

        # Section header
        emoji = "👤" if role.lower() == 'user' else "🤖"
        output.append(f"## {emoji} {role} - {timestamp}\n")

        # Main content
        output.append(f"{text_content}\n")

        # Tool calls (standard and detailed modes)
        if mode in ['standard', 'detailed']:
            tool_calls = extract_tool_calls(content_array)

            if tool_calls:
                output.append("**Tool Calls**:\n")

                for call in tool_calls:
                    if call.get('type') == 'tool_result':
                        # Tool result
                        result_content = call.get('content', '')
                        if result_content and mode == 'detailed':
                            output.append(f"- **Result**:\n```\n{result_content}\n```\n")
                    else:
                        # Tool use
                        name = call.get('name', '')
                        tool_input = call.get('input', {})

                        if name:
                            output.append(f"- **{name}**")
                            input_str = format_tool_input(tool_input)
                            if input_str:
                                output.append(f"\n    - {input_str}")
                            output.append("\n")

                output.append("\n")

        output.append("---\n")

    return '\n'.join(output)


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: python export-conversation.py <jsonl-file> [output-file] [mode]")
        print("\nModes:")
        print("  minimal   - User and assistant messages only (default)")
        print("  standard  - Everything in minimal + tool calls")
        print("  detailed  - Everything in standard + tool outputs and diffs")
        print("\nExamples:")
        print("  python export-conversation.py session.jsonl")
        print("  python export-conversation.py session.jsonl output.md")
        print("  python export-conversation.py session.jsonl output.md standard")
        sys.exit(1)

    # Parse arguments
    input_file = Path(sys.argv[1])

    # Output file
    if len(sys.argv) > 2:
        output_file = Path(sys.argv[2])
    else:
        output_file = Path(f"conversation-export_{datetime.now().strftime('%Y%m%d')}.md")

    # Mode
    mode = sys.argv[3] if len(sys.argv) > 3 else 'minimal'

    # Validate mode
    if mode not in ['minimal', 'standard', 'detailed']:
        print(f"Error: Invalid mode '{mode}'. Use: minimal, standard, or detailed", file=sys.stderr)
        sys.exit(1)

    # Parse conversation
    print(f"Reading conversation from: {input_file}")
    messages = parse_jsonl(input_file)
    print(f"Found {len(messages)} messages")

    if not messages:
        print("Warning: No messages found in conversation", file=sys.stderr)
        # Still create the file

    # Generate markdown
    print(f"Generating markdown in {mode} mode...")
    markdown = to_markdown(messages, mode)

    # Write output
    try:
        output_file.write_text(markdown, encoding='utf-8')
        print(f"\n✅ Exported to: {output_file}")
        print(f"📝 {len(messages)} messages exported")
        print(f"📊 Mode: {mode}")
    except Exception as e:
        print(f"Error: Failed to write output file: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
