#!/usr/bin/env python3
"""
审计文档并展示问题上下文
增强版：展示发现问题的文档片段、元数据（修改时间、文件大小）
"""
import os
import re
import argparse
from pathlib import Path
import json
from datetime import datetime


class DocumentAuditorWithContext:
    def __init__(self, project_root):
        self.project_root = Path(project_root)

    def get_file_metadata(self, file_path):
        """获取文件元数据"""
        try:
            mtime = os.path.getmtime(file_path)
            size = os.path.getsize(file_path)

            # 格式化修改时间
            mod_time = datetime.fromtimestamp(mtime).strftime('%Y-%m-%d %H:%M')

            # 格式化文件大小
            if size < 1024:
                size_str = f"{size} B"
            elif size < 1024 * 1024:
                size_str = f"{size / 1024:.1f} KB"
            else:
                size_str = f"{size / (1024 * 1024):.1f} MB"

            return {
                'modified_time': mod_time,
                'size_bytes': size,
                'size_formatted': size_str
            }
        except Exception as e:
            return {
                'modified_time': 'Unknown',
                'size_bytes': 0,
                'size_formatted': 'Unknown'
            }

    def extract_problematic_lines(self, doc_content, issues):
        """提取包含问题的文档行（标准模式：前后各2行）"""
        lines = doc_content.split('\n')
        problematic_sections = []

        for issue in issues:
            reference = issue.get('reference', '')

            # 查找包含引用的行
            for i, line in enumerate(lines):
                if reference in line:
                    # 提取上下文（前后各2行，标准模式）
                    start = max(0, i - 2)
                    end = min(len(lines), i + 3)

                    section = {
                        'line_number': i + 1,
                        'context': lines[start:end],
                        'highlight_index': i - start,  # 高亮行的索引
                        'issue': issue
                    }

                    # 避免重复
                    if not any(
                        s['line_number'] == section['line_number']
                        for s in problematic_sections
                    ):
                        problematic_sections.append(section)
                    break

        return problematic_sections

    def check_file_exists(self, file_path):
        """检查文件是否存在"""
        path = Path(file_path)
        if path.exists():
            return True

        full_path = self.project_root / file_path
        return full_path.exists()

    def extract_file_references(self, doc_content):
        """提取文档中的文件引用"""
        file_pattern = r'(?:[`:]?)([a-zA-Z0-9_\-./]+\.(?:py|js|ts|tsx|java|go|rs|sh|yaml|yml|json|sql))(?:`|\)|\s|$|,)'
        return re.findall(file_pattern, doc_content)

    def audit_document(self, doc_path):
        """审计文档并返回详细结果"""
        doc_path = Path(doc_path)

        try:
            with open(doc_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            return {
                'status': 'error',
                'reason': f'无法读取文件: {e}',
                'action': 'manual_review'
            }

        # 获取文件元数据
        metadata = self.get_file_metadata(doc_path)

        # 提取文件引用
        file_refs = self.extract_file_references(content)

        issues = []

        # 检查文件是否存在
        for file_ref in file_refs:
            if not self.check_file_exists(file_ref):
                issues.append({
                    'type': 'missing_file',
                    'severity': 'high',
                    'reference': file_ref,
                    'message': f'引用的文件不存在: {file_ref}'
                })

        # 提取问题行上下文
        if issues:
            problematic_sections = self.extract_problematic_lines(content, issues)
        else:
            problematic_sections = []

        # 判断文档状态
        if not issues:
            return {
                'status': 'current',
                'action': 'keep',
                'issues': [],
                'problematic_sections': [],
                'metadata': metadata
            }

        # 根据问题数量决定操作
        high_severity_count = sum(1 for i in issues if i['severity'] == 'high')

        if high_severity_count > 2:
            action = 'delete'
        elif high_severity_count > 0:
            action = 'update'
        else:
            action = 'review'

        return {
            'status': 'outdated',
            'action': action,
            'issues': issues,
            'problematic_sections': problematic_sections,
            'file_references': file_refs,
            'metadata': metadata
        }

    def format_report(self, audit_result, doc_path):
        """格式化审计报告为可读文本"""
        lines = []
        lines.append('='*70)
        lines.append(f'📄 文档: {Path(doc_path).name}')
        lines.append(f'路径: {doc_path}')
        lines.append('='*70)

        # 元数据
        metadata = audit_result.get('metadata', {})
        if metadata.get('modified_time'):
            lines.append(f'📅 最后修改: {metadata["modified_time"]}')
        if metadata.get('size_formatted'):
            lines.append(f'📦 文件大小: {metadata["size_formatted"]}')

        lines.append('')

        # 状态
        status = audit_result.get('status', 'unknown')
        action = audit_result.get('action', 'unknown')

        status_icons = {
            'current': '✅',
            'outdated': '⚠️ ',
            'error': '❌'
        }

        action_icons = {
            'keep': '💚 保留',
            'delete': '🗑️  删除',
            'update': '📝 更新',
            'review': '👀 人工审核'
        }

        lines.append(f'状态: {status_icons.get(status, "❓")} {status}')
        lines.append(f'建议操作: {action_icons.get(action, action)}')
        lines.append('')

        # 问题列表
        issues = audit_result.get('issues', [])
        if issues:
            lines.append(f'发现 {len(issues)} 个问题:')
            lines.append('')

            for issue in issues:
                severity = issue.get('severity', 'unknown')
                severity_icons = {
                    'high': '🔴',
                    'medium': '🟡',
                    'low': '🟢'
                }

                lines.append(f"  {severity_icons.get(severity, '⚪')} {issue['message']}")
            lines.append('')

        # 问题上下文（标准模式：前后各2行）
        sections = audit_result.get('problematic_sections', [])
        if sections:
            lines.append('问题详情（文档片段）:')
            lines.append('')

            for section in sections[:5]:  # 最多显示5个问题片段
                lines.append(f"📍 第 {section['line_number']} 行:")
                lines.append('')

                for i, ctx_line in enumerate(section['context']):
                    # 高亮问题行
                    if i == section['highlight_index']:
                        lines.append(f'  >>> {ctx_line}')
                    else:
                        lines.append(f'      {ctx_line}')

                lines.append('')
                lines.append(f"  问题: {section['issue']['message']}")
                lines.append('')

            if len(sections) > 5:
                lines.append(f'  ... 还有 {len(sections) - 5} 个问题片段')
                lines.append('')

        lines.append('='*70)

        return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description='审计文档并展示上下文')
    parser.add_argument('document', help='要审计的文档路径')
    parser.add_argument('--project-root', '-p', help='项目根目录', default='.')
    parser.add_argument('--output', '-o', help='输出文件路径（JSON 格式）')
    parser.add_argument('--show-report', '-s', help='显示可读报告', action='store_true')

    args = parser.parse_args()

    auditor = DocumentAuditorWithContext(args.project_root)
    result = auditor.audit_document(args.document)

    # 保存 JSON 结果
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
        print(f"✅ 审计完成，结果已保存到 {args.output}")

    # 显示报告
    if args.show_report or not args.output:
        report = auditor.format_report(result, args.document)
        print(report)


if __name__ == '__main__':
    main()
