#!/usr/bin/env python3
"""
收集文档上下文信息
只收集事实信息，不做任何判断
"""
import os
import re
import json
import argparse
import subprocess
from pathlib import Path
from datetime import datetime


class ContextCollector:
    def __init__(self, project_root):
        self.project_root = Path(project_root)

    def get_file_metadata(self, file_path):
        """获取文件元数据"""
        try:
            mtime = os.path.getmtime(file_path)
            size = os.path.getsize(file_path)

            # 格式化修改时间
            mod_time = datetime.fromtimestamp(mtime).strftime('%Y-%m-%d %H:%M')

            # 计算文件年龄（天数）
            age_days = (datetime.now() - datetime.fromtimestamp(mtime)).days

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
                'size_formatted': size_str,
                'age_days': age_days
            }
        except Exception as e:
            return {
                'modified_time': 'Unknown',
                'size_bytes': 0,
                'size_formatted': 'Unknown',
                'age_days': 0
            }

    def get_git_history(self, doc_path, max_commits=5):
        """获取 Git 历史"""
        try:
            result = subprocess.run([
                'git', 'log',
                '--pretty=format:%H|%ai|%s',
                '--max-count', str(max_commits),
                str(doc_path)
            ], capture_output=True, text=True, cwd=self.project_root)

            if result.returncode != 0:
                return {'commits': [], 'total_commits': 0, 'days_since_last_commit': None}

            history = []
            now = datetime.now()
            for line in result.stdout.strip().split('\n'):
                if line:
                    parts = line.split('|', 2)
                    if len(parts) == 3:
                        commit_date = datetime.fromisoformat(parts[1].replace('+00:00', ''))
                        history.append({
                            'hash': parts[0],
                            'date': parts[1],
                            'message': parts[2],
                            'days_ago': (now - commit_date).days
                        })

            # 计算生命周期特征
            lifecycle_pattern = self._infer_lifecycle_pattern(history)

            return {
                'commits': history,
                'total_commits': len(history),
                'days_since_last_commit': history[0]['days_ago'] if history else None,
                'lifecycle_pattern': lifecycle_pattern
            }
        except Exception:
            return {'commits': [], 'total_commits': 0, 'days_since_last_commit': None, 'lifecycle_pattern': 'unknown'}

    def _infer_lifecycle_pattern(self, history):
        """推断生命周期模式（基于事实，不做判断）"""
        if not history:
            return 'no_git_history'

        total_commits = len(history)
        days_since_last = history[0]['days_ago']
        age_days = history[-1]['days_ago']

        if total_commits == 1:
            if days_since_last < 7:
                return 'one_time_created_recently'
            else:
                return 'one_time_created_old'
        elif total_commits > 1:
            time_span = age_days + 1
            commit_frequency = total_commits / time_span

            if commit_frequency > 0.5:
                return 'frequently_updated'
            elif days_since_last < 30:
                return 'actively_maintained'
            else:
                return 'abandoned_or_complete'

        return 'unknown'

    def extract_document_structure(self, content):
        """提取文档结构"""
        lines = content.split('\n')

        # 提取标题
        headings = []
        for line in lines:
            if line.startswith('#'):
                headings.append(line.strip())

        # 提取标题
        title = ''
        for line in lines[:20]:
            if line.startswith('#'):
                title = line.strip()
                break

        # 提取第一段
        first_paragraph = []
        for line in lines:
            if line.strip() == '':
                if first_paragraph:
                    break
                continue
            if not line.startswith('#'):
                first_paragraph.append(line.strip())

        return {
            'headings': headings,
            'title': title,
            'first_paragraph': ' '.join(first_paragraph[:3])  # 前 3 句
        }

    def extract_issues_with_context(self, content, project_root):
        """提取问题及上下文"""
        issues = []
        lines = content.split('\n')

        # 提取文件引用
        file_pattern = r'(?:[`:]?)([a-zA-Z0-9_\-./]+\.(?:py|js|ts|tsx|java|go|rs|sh|yaml|yml|json|sql))(?:`|\)|\s|$|,)'
        file_refs = re.findall(file_pattern, content)

        # 检查每个引用
        for ref in file_refs:
            exists = self._check_file_exists(ref)

            if not exists:
                # 找到问题所在的行
                for i, line in enumerate(lines):
                    if ref in line:
                        # 提取上下文（前后各 2 行）
                        start = max(0, i - 2)
                        end = min(len(lines), i + 3)

                        issues.append({
                            'type': 'missing_file',
                            'reference': ref,
                            'line_number': i + 1,
                            'context': lines[start:end],
                            'exists': False
                        })
                        break

        return {
            'total_issues': len(issues),
            'issues': issues
        }

    def _check_file_exists(self, file_path):
        """检查文件是否存在"""
        path = Path(file_path)
        if path.exists():
            return True

        full_path = self.project_root / file_path
        return full_path.exists()

    def collect_context(self, doc_path):
        """收集文档的所有上下文信息"""
        doc_path = Path(doc_path)

        try:
            with open(doc_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            return {
                'error': f'无法读取文件: {e}',
                'doc_path': str(doc_path)
            }

        # 收集所有信息
        metadata = self.get_file_metadata(doc_path)
        git_history = self.get_git_history(doc_path)
        doc_structure = self.extract_document_structure(content)
        issues_data = self.extract_issues_with_context(content, self.project_root)

        # 返回结构化上下文
        return {
            'doc_path': str(doc_path),
            'doc_name': doc_path.name,
            'metadata': metadata,
            'git_history': git_history,
            'document_structure': doc_structure,
            'issues': issues_data
        }


def main():
    parser = argparse.ArgumentParser(description='收集文档上下文信息')
    parser.add_argument('document', help='文档路径')
    parser.add_argument('--project-root', '-p', help='项目根目录', default='.')
    parser.add_argument('--output', '-o', help='输出文件路径（JSON 格式）')

    args = parser.parse_args()

    collector = ContextCollector(args.project_root)
    context = collector.collect_context(args.document)

    # 输出 JSON
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(context, f, ensure_ascii=False, indent=2)
        print(f"✅ 上下文信息已保存到: {args.output}")
    else:
        print(json.dumps(context, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
