#!/usr/bin/env python3
"""
审计单个 Markdown 文档，判断是否过时
"""
import os
import re
import argparse
from pathlib import Path
import json


class DocumentAuditor:
    def __init__(self, project_root):
        self.project_root = Path(project_root)

    def extract_code_references(self, doc_content):
        """从文档中提取代码引用"""
        references = {
            'file_paths': [],
            'function_names': [],
            'class_names': [],
            'variables': [],
            'api_endpoints': [],
            'code_blocks': []
        }

        # 提取文件路径（如: src/utils/helper.py, ./scripts/test.sh）
        file_pattern = r'(?:[`:]?)([a-zA-Z0-9_\-./]+\.(?:py|js|ts|tsx|java|go|rs|sh|yaml|yml|json|sql))(?:`|\)|\s|$|,)'
        references['file_paths'].extend(re.findall(file_pattern, doc_content))

        # 提取代码块内容
        code_block_pattern = r'```(?:python|javascript|typescript|java|go|rust|bash|sh)?\n(.*?)```'
        references['code_blocks'].extend(re.findall(code_block_pattern, doc_content, re.DOTALL))

        # 从代码块中提取函数名、类名、变量
        for code in references['code_blocks']:
            # 函数定义
            references['function_names'].extend(re.findall(r'def\s+(\w+)\s*\(', code))
            references['function_names'].extend(re.findall(r'function\s+(\w+)\s*\(', code))

            # 类定义
            references['class_names'].extend(re.findall(r'class\s+(\w+)\s*[:\(]', code))

            # 变量赋值
            references['variables'].extend(re.findall(r'(\w+)\s*=\s*', code))

        # API 端点
        api_pattern = r'(?:GET|POST|PUT|DELETE|PATCH)\s+([\/\w\-{}]+)'
        references['api_endpoints'].extend(re.findall(api_pattern, doc_content))

        # 去重
        for key in references:
            references[key] = list(set(references[key]))

        return references

    def check_file_exists(self, file_path):
        """检查文件是否存在"""
        # 尝试相对路径和绝对路径
        path = Path(file_path)
        if path.exists():
            return True

        # 尝试从项目根目录
        full_path = self.project_root / file_path
        return full_path.exists()

    def search_in_codebase(self, pattern, file_types=None):
        """在代码库中搜索模式"""
        if file_types is None:
            file_types = ['.py', '.js', '.ts', '.tsx', '.java', '.go', '.rs']

        matches = []
        for ext in file_types:
            for file_path in self.project_root.rglob(f'*{ext}'):
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        if re.search(pattern, content):
                            matches.append(str(file_path))
                except Exception:
                    continue

        return matches

    def audit_document(self, doc_path):
        """审计文档，返回过时状态"""
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

        # 提取代码引用
        references = self.extract_code_references(content)

        issues = []

        # 检查文件路径是否存在
        for file_path in references['file_paths']:
            if not self.check_file_exists(file_path):
                issues.append({
                    'type': 'missing_file',
                    'severity': 'high',
                    'reference': file_path,
                    'message': f'引用的文件不存在: {file_path}'
                })

        # 检查函数名是否存在于代码库中
        for func_name in references['function_names']:
            pattern = rf'\bdef\s+{func_name}\s*\(|\bfunction\s+{func_name}\s*\('
            matches = self.search_in_codebase(pattern)
            if not matches:
                issues.append({
                    'type': 'missing_function',
                    'severity': 'medium',
                    'reference': func_name,
                    'message': f'函数可能在代码库中不存在: {func_name}()'
                })

        # 检查类名是否存在于代码库中
        for class_name in references['class_names']:
            pattern = rf'\bclass\s+{class_name}\s*[:\(]'
            matches = self.search_in_codebase(pattern)
            if not matches:
                issues.append({
                    'type': 'missing_class',
                    'severity': 'medium',
                    'reference': class_name,
                    'message': f'类可能在代码库中不存在: {class_name}'
                })

        # 判断文档状态
        if not issues:
            return {
                'status': 'current',
                'action': 'keep',
                'issues': []
            }

        # 根据问题严重程度决定操作
        high_severity_count = sum(1 for i in issues if i['severity'] == 'high')
        medium_severity_count = sum(1 for i in issues if i['severity'] == 'medium')

        if high_severity_count > 0:
            action = 'delete' if high_severity_count > 2 else 'update'
        elif medium_severity_count > 3:
            action = 'update'
        else:
            action = 'review'

        return {
            'status': 'outdated',
            'action': action,
            'issues': issues,
            'references': references
        }


def main():
    parser = argparse.ArgumentParser(description='审计 Markdown 文档是否过时')
    parser.add_argument('document', help='要审计的文档路径')
    parser.add_argument('--project-root', '-p', help='项目根目录', default='.')
    parser.add_argument('--output', '-o', help='输出文件路径（JSON 格式）')

    args = parser.parse_args()

    auditor = DocumentAuditor(args.project_root)
    result = auditor.audit_document(args.document)

    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
        print(f"✅ 审计完成，结果已保存到 {args.output}")
    else:
        print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
