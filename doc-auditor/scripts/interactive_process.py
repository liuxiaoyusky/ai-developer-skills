#!/usr/bin/env python3
"""
交互式文档处理脚本
支持分组确认、按严重程度排序、显示元数据
"""
import os
import sys
import json
import subprocess
from pathlib import Path
from collections import defaultdict


class InteractiveProcessor:
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.auditor_script = Path(__file__).parent / 'audit_with_context.py'

    def audit_document(self, doc_path):
        """使用增强版审计脚本审计文档"""
        try:
            result = subprocess.run([
                'python',
                str(self.auditor_script),
                doc_path,
                '--project-root', str(self.project_root)
            ], capture_output=True, text=True, timeout=30)

            if result.returncode == 0:
                # 从 stderr 中提取 JSON（如果有 --output 参数的话）
                # 这里我们重新解析，因为 audit_with_context 的输出格式
                import re
                # 简单判断：如果输出包含 "📄" 则是报告格式
                if '📄' in result.stdout:
                    # 解析报告文本获取关键信息
                    return self.parse_text_report(result.stdout, doc_path)
                else:
                    return json.loads(result.stdout)
            else:
                return {
                    'status': 'error',
                    'action': 'manual_review',
                    'issues': [],
                    'error': result.stderr
                }
        except Exception as e:
            return {
                'status': 'error',
                'action': 'manual_review',
                'issues': [],
                'error': str(e)
            }

    def parse_text_report(self, report_text, doc_path):
        """从文本报告中解析关键信息"""
        lines = report_text.split('\n')

        result = {
            'path': doc_path,
            'status': 'current',
            'action': 'keep',
            'issues': [],
            'metadata': {}
        }

        for line in lines:
            if '状态:' in line:
                if 'outdated' in line:
                    result['status'] = 'outdated'
                elif 'error' in line:
                    result['status'] = 'error'

            if '建议操作:' in line:
                if '删除' in line:
                    result['action'] = 'delete'
                elif '更新' in line:
                    result['action'] = 'update'
                elif '审核' in line:
                    result['action'] = 'review'

            if '🔴' in line or '🟡' in line:
                result['issues'].append({
                    'severity': 'high' if '🔴' in line else 'medium',
                    'message': line.strip()
                })

            if '📅 最后修改:' in line:
                result['metadata']['modified_time'] = line.split(':')[1].strip()

            if '📦 文件大小:' in line:
                result['metadata']['size_formatted'] = line.split(':')[1].strip()

        result['issues_count'] = len(result['issues'])

        return result

    def group_documents(self, documents):
        """按操作类型分组文档"""
        groups = defaultdict(list)

        for doc in documents:
            action = doc.get('action', 'keep')
            groups[action].append(doc)

        # 按问题数量排序
        for action in groups:
            groups[action].sort(key=lambda x: x.get('issues_count', 0), reverse=True)

        return groups

    def display_document_summary(self, doc, index, total):
        """显示单个文档的摘要信息"""
        path = Path(doc['path'])
        metadata = doc.get('metadata', {})
        issues = doc.get('issues', [])

        print(f"\n[{index}/{total}] {path.name} ({len(issues)} 个问题)")
        print('━' * 70)

        if metadata.get('modified_time'):
            print(f"📅 最后修改: {metadata['modified_time']}")
        if metadata.get('size_formatted'):
            print(f"📦 文件大小: {metadata['size_formatted']}")

        action = doc.get('action', 'keep')
        action_icons = {
            'delete': '🗑️  删除',
            'update': '📝 更新',
            'review': '👀 人工审核'
        }
        print(f"建议操作: {action_icons.get(action, action)}")

        # 显示前3个问题
        if issues:
            print(f"\n前 {min(3, len(issues))} 个问题:")
            for issue in issues[:3]:
                severity = issue.get('severity', 'unknown')
                icon = '🔴' if severity == 'high' else '🟡' if severity == 'medium' else '🟢'
                message = issue.get('message', issue)
                print(f"  {icon} {message}")

            if len(issues) > 3:
                print(f"  ... 还有 {len(issues) - 3} 个问题")

    def get_group_choice(self, group_name, group_docs, total_docs):
        """获取用户对整组的操作选择"""
        action_names = {
            'delete': '🗑️  需要删除',
            'update': '📝 需要更新',
            'review': '👀 需要人工审核'
        }

        print(f"\n{'━' * 70}")
        print(f"{action_names.get(group_name, group_name)}的文档 ({len(group_docs)}个)")
        print(f"{'━' * 70}")
        print(f"\n对该组的操作:")
        print(f"  [y] 全部应用 ({len(group_docs)}个)")
        print(f"  [s] 逐个确认")
        print(f"  [j] 跳过该组")
        print(f"  [q] 退出")

        while True:
            choice = input(f"\n你的选择 [y/s/j/q]: ").strip().lower()

            if choice in ['y', 's', 'j', 'q']:
                return choice
            elif choice == '':
                # 默认逐个确认
                return 's'
            else:
                print("❌ 无效选择，请输入 y/s/j/q")

    def get_document_choice(self, doc):
        """获取用户对单个文档的操作选择"""
        action = doc.get('action', 'keep')

        print(f"\n{'━' * 70}")
        print(f"对该文档的操作:")

        if action == 'delete':
            print(f"  [y] 删除 (创建备份)")
            print(f"  [n] 跳过")
        elif action == 'update':
            print(f"  [y] 更新 (添加警告标记)")
            print(f"  [n] 跳过")
        else:
            print(f"  [n] 跳过 (保留文档)")

        print(f"  [q] 退出处理")

        while True:
            choice = input(f"\n你的选择 [y/n/q]: ").strip().lower()

            if choice in ['y', 'n', 'q']:
                return choice
            elif choice == '':
                return 'n'
            else:
                print("❌ 无效选择，请输入 y/n/q")

    def delete_document(self, doc_path, backup=True):
        """删除文档"""
        doc_path = Path(doc_path)

        if backup:
            backup_path = doc_path.with_suffix('.md.backup')
            import shutil
            try:
                shutil.copy2(doc_path, backup_path)
                print(f"  📦 备份已创建: {backup_path.name}")
            except Exception as e:
                print(f"  ⚠️  备份失败: {e}")
                return False

        try:
            doc_path.unlink()
            print(f"  🗑️  已删除: {doc_path.name}")
            return True
        except Exception as e:
            print(f"  ❌ 删除失败: {e}")
            return False

    def update_document(self, doc_path):
        """更新文档，添加过时警告"""
        doc_path = Path(doc_path)

        try:
            with open(doc_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"  ❌ 无法读取文件: {e}")
            return False

        warning = "> **⚠️ 文档已过时**\n> \n> 此文档包含过时信息，请谨慎参考。\n\n---\n\n"

        if not content.startswith('> **⚠️ 文档已过时**'):
            updated_content = warning + content
        else:
            print(f"  ℹ️  文档已包含警告标记")
            return True

        try:
            with open(doc_path, 'w', encoding='utf-8') as f:
                f.write(updated_content)
            print(f"  ✅ 已更新: {doc_path.name}")
            return True
        except Exception as e:
            print(f"  ❌ 更新失败: {e}")
            return False

    def process_interactive(self, manifest_path, limit=None):
        """交互式处理文档"""
        # 读取审计清单
        with open(manifest_path, 'r') as f:
            manifest = json.load(f)

        docs_to_audit = manifest.get('files', [])
        if limit:
            docs_to_audit = docs_to_audit[:limit]

        print(f"📋 开始审计 {len(docs_to_audit)} 个文档...\n")

        # 审计所有文档
        all_results = []
        for i, doc_path in enumerate(docs_to_audit, 1):
            print(f"[{i}/{len(docs_to_audit)}] 审计: {Path(doc_path).name}")
            result = self.audit_document(doc_path)
            result['path'] = doc_path
            all_results.append(result)

        # 分组
        groups = self.group_documents(all_results)

        # 显示汇总
        print(f"\n{'='*70}")
        print(f"📊 审计结果汇总")
        print(f"{'='*70}")
        print(f"  🗑️  需要删除: {len(groups.get('delete', []))} 个")
        print(f"  📝 需要更新: {len(groups.get('update', []))} 个")
        print(f"  👀 需要人工审核: {len(groups.get('review', []))} 个")
        print(f"  💚 保留: {len(groups.get('keep', []))} 个")

        # 处理各组
        stats = {'deleted': 0, 'updated': 0, 'kept': 0, 'skipped': 0}

        # 按优先级处理：delete > update > review
        for group_name in ['delete', 'update', 'review']:
            if group_name not in groups:
                continue

            group_docs = groups[group_name]
            if not group_docs:
                continue

            # 询问用户对整组的操作
            group_choice = self.get_group_choice(group_name, group_docs, len(all_results))

            if group_choice == 'q':
                print("\n👋 用户取消操作")
                break
            elif group_choice == 'j':
                print(f"  ⏭️  跳过该组 ({len(group_docs)} 个文档)")
                stats['skipped'] += len(group_docs)
                continue
            elif group_choice == 'y':
                # 全部应用
                print(f"\n⚙️  批量处理该组 ({len(group_docs)} 个文档)...")
                for doc in group_docs:
                    self.process_single_document(doc, stats)
            elif group_choice == 's':
                # 逐个确认
                print(f"\n⚙️  逐个处理该组 ({len(group_docs)} 个文档)...")
                for i, doc in enumerate(group_docs, 1):
                    self.display_document_summary(doc, i, len(group_docs))

                    doc_choice = self.get_document_choice(doc)

                    if doc_choice == 'q':
                        print("\n👋 用户取消操作")
                        return self.show_final_stats(stats, len(all_results))
                    elif doc_choice == 'y':
                        self.process_single_document(doc, stats)
                    else:
                        print(f"  ⏭️  跳过: {Path(doc['path']).name}")
                        stats['skipped'] += 1

        return self.show_final_stats(stats, len(all_results))

    def process_single_document(self, doc, stats):
        """处理单个文档"""
        doc_path = doc['path']
        action = doc.get('action', 'keep')

        if action == 'delete':
            if self.delete_document(doc_path):
                stats['deleted'] += 1
            else:
                stats['skipped'] += 1
        elif action == 'update':
            if self.update_document(doc_path):
                stats['updated'] += 1
            else:
                stats['skipped'] += 1
        else:
            stats['kept'] += 1

    def show_final_stats(self, stats, total):
        """显示最终统计"""
        print(f"\n{'='*70}")
        print(f"✅ 处理完成")
        print(f"{'='*70}")
        print(f"  🗑️  删除: {stats['deleted']}")
        print(f"  📝 更新: {stats['updated']}")
        print(f"  💚 保留: {stats['kept']}")
        print(f"  ⏭️  跳过: {stats['skipped']}")
        print(f"{'='*70}")
        return stats


def main():
    import argparse

    parser = argparse.ArgumentParser(description='交互式处理文档')
    parser.add_argument('manifest', help='审计清单文件（JSON 格式）')
    parser.add_argument('--project-root', '-p', help='项目根目录', default='.')
    parser.add_argument('--limit', '-l', type=int, help='限制处理文档数量（测试用）')

    args = parser.parse_args()

    processor = InteractiveProcessor(args.project_root)
    processor.process_interactive(args.manifest, limit=args.limit)


if __name__ == '__main__':
    main()
