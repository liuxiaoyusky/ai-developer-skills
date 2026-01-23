#!/usr/bin/env python3
"""
扫描项目中所有 Markdown 文档
"""
import os
import argparse
from pathlib import Path
import json


def find_markdown_files(root_dir, exclude_dirs=None):
    """查找所有 Markdown 文件"""
    if exclude_dirs is None:
        exclude_dirs = ['.git', 'node_modules', '__pycache__', '.venv', 'venv', 'dist', 'build']

    md_files = []
    root_path = Path(root_dir)

    for file_path in root_path.rglob('*.md'):
        # 排除特定目录
        if any(excluded in file_path.parts for excluded in exclude_dirs):
            continue

        md_files.append(str(file_path))

    return sorted(md_files)


def main():
    parser = argparse.ArgumentParser(description='扫描项目中的 Markdown 文档')
    parser.add_argument('directory', help='项目根目录', default='.', nargs='?')
    parser.add_argument('--output', '-o', help='输出文件路径（JSON 格式）')
    parser.add_argument('--exclude', '-e', help='要排除的目录（逗号分隔）', default='')

    args = parser.parse_args()

    # 处理排除目录
    exclude_dirs = ['.git', 'node_modules', '__pycache__', '.venv', 'venv', 'dist', 'build']
    if args.exclude:
        exclude_dirs.extend([d.strip() for d in args.exclude.split(',')])

    # 查找 Markdown 文件
    md_files = find_markdown_files(args.directory, exclude_dirs)

    result = {
        'total_count': len(md_files),
        'files': md_files
    }

    # 输出结果
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
        print(f"✅ 找到 {len(md_files)} 个 Markdown 文件，结果已保存到 {args.output}")
    else:
        print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
