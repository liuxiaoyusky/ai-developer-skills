#!/usr/bin/env python3
"""
批量处理文档：删除或更新过时文档
"""
import os
import json
import argparse
from pathlib import Path
from audit_document import DocumentAuditor


def delete_document(doc_path, backup=True):
    """删除文档"""
    doc_path = Path(doc_path)

    if backup:
        # 创建备份
        backup_path = doc_path.with_suffix('.md.backup')
        import shutil
        shutil.copy2(doc_path, backup_path)
        print(f"📦 备份已创建: {backup_path}")

    # 删除文件
    doc_path.unlink()
    print(f"🗑️  已删除: {doc_path}")

    return True


def update_document(doc_path, issues):
    """更新文档，添加过时标记"""
    doc_path = Path(doc_path)

    try:
        with open(doc_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"❌ 无法读取文件: {e}")
        return False

    # 在文档开头添加过时警告
    warning = "> **⚠️ 文档已过时**\n"
    warning += "> \n"

    # 根据问题类型添加具体警告
    missing_files = [i for i in issues if i['type'] == 'missing_file']
    missing_funcs = [i for i in issues if i['type'] == 'missing_function']
    missing_classes = [i for i in issues if i['type'] == 'missing_class']

    if missing_files:
        warning += f"> - 以下文件不存在: {', '.join([i['reference'] for i in missing_files])}\n"
    if missing_funcs:
        warning += f"> - 以下函数可能已删除: {', '.join([i['reference'] for i in missing_funcs])}\n"
    if missing_classes:
        warning += f"> - 以下类可能已删除: {', '.join([i['reference'] for i in missing_classes])}\n"

    warning += "> \n"
    warning += "> 请更新文档以反映当前代码状态。\n"
    warning += "\n---\n\n"

    # 检查是否已经有警告
    if not content.startswith('> **⚠️ 文档已过时**'):
        updated_content = warning + content
    else:
        # 更新现有警告
        lines = content.split('\n')
        new_content = []
        skip_until_separator = False

        for line in lines:
            if line.strip() == '---' and skip_until_separator:
                skip_until_separator = False
                continue
            if skip_until_separator:
                continue
            if line.startswith('> **⚠️'):
                skip_until_separator = True
                new_content.append(warning.strip())
                continue
            new_content.append(line)

        updated_content = '\n'.join(new_content)

    # 写入更新后的内容
    try:
        with open(doc_path, 'w', encoding='utf-8') as f:
            f.write(updated_content)
        print(f"✅ 已更新: {doc_path}")
        return True
    except Exception as e:
        print(f"❌ 无法写入文件: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description='批量处理文档')
    parser.add_argument('manifest', help='审计结果清单（JSON 格式）')
    parser.add_argument('--project-root', '-p', help='项目根目录', default='.')
    parser.add_argument('--dry-run', '-d', help='模拟运行，不实际修改文件', action='store_true')
    parser.add_argument('--backup', '-b', help='删除前创建备份', action='store_true', default=True)

    args = parser.parse_args()

    # 读取审计清单
    with open(args.manifest, 'r', encoding='utf-8') as f:
        manifest = json.load(f)

    stats = {
        'deleted': 0,
        'updated': 0,
        'kept': 0,
        'errors': 0
    }

    # 处理每个文档
    for doc_info in manifest.get('documents', []):
        doc_path = doc_info['path']
        action = doc_info.get('action', 'keep')
        issues = doc_info.get('issues', [])

        print(f"\n处理: {doc_path}")
        print(f"操作: {action}")

        if action == 'delete':
            if args.dry_run:
                print(f"🔍 [模拟] 将删除: {doc_path}")
                stats['deleted'] += 1
            else:
                if delete_document(doc_path, backup=args.backup):
                    stats['deleted'] += 1
                else:
                    stats['errors'] += 1

        elif action == 'update':
            if args.dry_run:
                print(f"🔍 [模拟] 将更新: {doc_path}")
                stats['updated'] += 1
            else:
                if update_document(doc_path, issues):
                    stats['updated'] += 1
                else:
                    stats['errors'] += 1

        else:  # keep
            print(f"✅ 保留: {doc_path}")
            stats['kept'] += 1

    # 输出统计
    print(f"\n{'='*50}")
    print(f"处理完成:")
    print(f"  删除: {stats['deleted']}")
    print(f"  更新: {stats['updated']}")
    print(f"  保留: {stats['kept']}")
    print(f"  错误: {stats['errors']}")
    print(f"{'='*50}")

    if args.dry_run:
        print("\n⚠️  这是模拟运行，没有实际修改文件")
        print("   如需实际执行，请移除 --dry-run 参数")


if __name__ == '__main__':
    main()
