#!/usr/bin/env python3
"""
Claude Skills Checker - 检查本地skills和marketplace插件更新

使用方法:
    python3 check_skills.py              # 检查所有
    python3 check_skills.py --local      # 仅检查本地skills
    python3 check_skills.py --plugins    # 仅检查插件
    python3 check_skills.py --update     # 自动更新所有
    python3 check_skills.py --json       # 输出JSON格式
    python3 check_skills.py --my-skills  # 显示我的常用skills
    python3 check_skills.py --record <skill-name>  # 记录使用的skill
"""

import json
import os
import subprocess
from collections import Counter
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Dict, List, Optional


class UpdateStatus(Enum):
    """更新状态"""
    UP_TO_DATE = "up_to_date"
    UPDATE_AVAILABLE = "update_available"
    ERROR = "error"
    UNKNOWN = "unknown"


@dataclass
class SkillInfo:
    """Skill信息"""
    name: str
    type: str  # "official", "custom"
    source: str  # 源路径
    is_broken: bool = False


@dataclass
class PluginInfo:
    """插件信息"""
    name: str
    marketplace: str
    version: str
    installed_at: str
    install_path: str
    git_commit_sha: str


@dataclass
class MarketplaceUpdate:
    """Marketplace更新信息"""
    name: str
    repo: str
    local_commit: str
    remote_commit: str
    status: UpdateStatus
    affected_plugins: List[PluginInfo] = field(default_factory=list)
    commits_behind: List[str] = field(default_factory=list)


class SkillsChecker:
    """Skills检查器"""

    def __init__(self, claude_dir: Optional[Path] = None):
        self.claude_dir = claude_dir or Path.home() / ".claude"
        self.skills_dir = self.claude_dir / "skills"
        self.plugins_dir = self.claude_dir / "plugins"

        self.local_skills: List[SkillInfo] = []
        self.installed_plugins: List[PluginInfo] = []
        self.marketplace_updates: List[MarketplaceUpdate] = []

    def check_all(self) -> Dict:
        """检查所有"""
        self.scan_local_skills()
        self.scan_installed_plugins()
        self.check_marketplace_updates()

        return {
            "local_skills": len(self.local_skills),
            "installed_plugins": len(self.installed_plugins),
            "marketplaces_need_update": sum(
                1 for m in self.marketplace_updates
                if m.status == UpdateStatus.UPDATE_AVAILABLE
            ),
            "timestamp": datetime.now().isoformat()
        }

    def scan_local_skills(self):
        """扫描本地skills"""
        skills_dir = self.skills_dir

        if not skills_dir.exists():
            return

        for item in skills_dir.iterdir():
            if item.is_symlink():
                # 软链接 -> 官方skill
                target = item.resolve()
                is_broken = not target.exists()

                self.local_skills.append(SkillInfo(
                    name=item.name,
                    type="official" if "official/skills" in str(target) else "symlink",
                    source=str(target.relative_to(self.claude_dir)),
                    is_broken=is_broken
                ))
            elif item.is_dir():
                # 实体目录 -> 自定义skill
                if item.name not in ["official"]:
                    self.local_skills.append(SkillInfo(
                        name=item.name,
                        type="custom",
                        source=str(item.relative_to(self.claude_dir))
                    ))

    def scan_installed_plugins(self):
        """扫描已安装的插件"""
        installed_json = self.plugins_dir / "installed_plugins.json"

        if not installed_json.exists():
            return

        try:
            data = json.loads(installed_json.read_text())

            for plugin_id, versions in data.get("plugins", {}).items():
                if not versions:
                    continue

                latest = versions[0]  # 取第一个（最新）

                # 解析 plugin-name@marketplace
                if "@" in plugin_id:
                    name, marketplace = plugin_id.split("@", 1)
                else:
                    name, marketplace = plugin_id, "unknown"

                self.installed_plugins.append(PluginInfo(
                    name=name,
                    marketplace=marketplace,
                    version=latest.get("version", "unknown"),
                    installed_at=latest.get("installedAt", ""),
                    install_path=latest.get("installPath", ""),
                    git_commit_sha=latest.get("gitCommitSha", "")
                ))
        except (json.JSONDecodeError, KeyError) as e:
            print(f"⚠️ 无法解析 installed_plugins.json: {e}")

    def check_marketplace_updates(self):
        """检查marketplace更新"""
        known_json = self.plugins_dir / "known_marketplaces.json"

        if not known_json.exists():
            return

        try:
            data = json.loads(known_json.read_text())

            for marketplace_name, info in data.items():
                install_path = info.get("installLocation")
                source_info = info.get("source", {})

                if not install_path or not Path(install_path).exists():
                    continue

                update_info = self._check_git_updates(
                    marketplace_name,
                    Path(install_path),
                    source_info
                )

                # 查找受影响的插件
                affected = [
                    p for p in self.installed_plugins
                    if p.marketplace == marketplace_name
                ]
                update_info.affected_plugins = affected

                self.marketplace_updates.append(update_info)

        except (json.JSONDecodeError, KeyError) as e:
            print(f"⚠️ 无法解析 known_marketplaces.json: {e}")

    def _check_git_updates(
        self,
        name: str,
        path: Path,
        source_info: Dict
    ) -> MarketplaceUpdate:
        """检查git仓库更新"""
        try:
            # 获取本地commit
            local_commit = self._run_git_command(path, "rev-parse", "HEAD")

            # Fetch远程
            subprocess.run(
                ["git", "fetch", "--quiet", "origin"],
                cwd=path,
                check=False,
                capture_output=True
            )

            # 获取远程commit
            remote_commit = self._run_git_command(
                path, "rev-parse", "origin/main"
            )

            # 获取commits behind
            commits_behind = self._run_git_command(
                path, "log", f"HEAD..origin/main", "--oneline"
            ).split("\n") if local_commit != remote_commit else []

            status = (
                UpdateStatus.UP_TO_DATE
                if local_commit == remote_commit
                else UpdateStatus.UPDATE_AVAILABLE
            )

            return MarketplaceUpdate(
                name=name,
                repo=source_info.get("repo", "unknown"),
                local_commit=local_commit[:8],
                remote_commit=remote_commit[:8],
                status=status,
                commits_behind=commits_behind[:10]  # 最多显示10条
            )

        except Exception as e:
            return MarketplaceUpdate(
                name=name,
                repo=source_info.get("repo", "unknown"),
                local_commit="error",
                remote_commit="error",
                status=UpdateStatus.ERROR
            )

    def _run_git_command(self, path: Path, *args) -> str:
        """运行git命令"""
        result = subprocess.run(
            ["git"] + list(args),
            cwd=path,
            check=True,
            capture_output=True,
            text=True
        )
        return result.stdout.strip()

    def update_marketplace(self, name: str) -> bool:
        """更新marketplace"""
        marketplace = next(
            (m for m in self.marketplace_updates if m.name == name),
            None
        )

        if not marketplace:
            print(f"❌ 未找到marketplace: {name}")
            return False

        path = self.plugins_dir / "marketplaces" / marketplace.name

        try:
            result = subprocess.run(
                ["git", "pull", "origin", "main"],
                cwd=path,
                check=True,
                capture_output=True,
                text=True
            )
            print(f"✅ {name} 已更新到最新版本")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ 更新失败: {e.stderr}")
            return False

    def print_report(self):
        """打印报告"""
        print("=" * 60)
        print("🔍 Claude Skills 状态报告")
        print("=" * 60)

        # 本地Skills
        print(f"\n📁 本地Skills ({len(self.local_skills)}个)")
        print("-" * 60)

        for skill in sorted(self.local_skills, key=lambda x: x.name):
            status = "❌ 断开" if skill.is_broken else "✅"
            type_label = "官方" if skill.type == "official" else "自定义"
            print(f"[{type_label}] {status} {skill.name} ({skill.source})")

        # Marketplace插件
        print(f"\n📦 Marketplace插件 ({len(self.installed_plugins)}个)")
        print("-" * 60)

        # 按marketplace分组
        plugins_by_marketplace: Dict[str, List[PluginInfo]] = {}
        for plugin in self.installed_plugins:
            if plugin.marketplace not in plugins_by_marketplace:
                plugins_by_marketplace[plugin.marketplace] = []
            plugins_by_marketplace[plugin.marketplace].append(plugin)

        for marketplace, plugins in sorted(plugins_by_marketplace.items()):
            # 查找更新状态
            marketplace_update = next(
                (m for m in self.marketplace_updates if m.name == marketplace),
                None
            )

            if marketplace_update:
                status_icon = {
                    UpdateStatus.UP_TO_DATE: "✅ 最新",
                    UpdateStatus.UPDATE_AVAILABLE: "⚠️ 可更新",
                    UpdateStatus.ERROR: "❌ 错误"
                }.get(marketplace_update.status, "❓ 未知")

                print(f"\n[{marketplace}] {status_icon}")
                if marketplace_update.status == UpdateStatus.UPDATE_AVAILABLE:
                    print(f"  本地: {marketplace_update.local_commit} → 远程: {marketplace_update.remote_commit}")
            else:
                print(f"\n[{marketplace}]")

            for plugin in sorted(plugins, key=lambda x: x.name):
                version = plugin.version[:8] if len(plugin.version) > 8 else plugin.version
                print(f"  • {plugin.name} (v{version})")

        # 更新汇总
        print("\n" + "=" * 60)
        print("📊 更新汇总")
        print("=" * 60)

        needs_update = [
            m for m in self.marketplace_updates
            if m.status == UpdateStatus.UPDATE_AVAILABLE
        ]

        if needs_update:
            print(f"\n⚠️ {len(needs_update)} 个marketplace有更新:\n")

            for update in needs_update:
                print(f"📦 [{update.name}]")
                print(f"   {update.repo}")
                print(f"   {update.local_commit} → {update.remote_commit}")

                if update.commits_behind:
                    print(f"   最新变更:")
                    for commit in update.commits_behind[:5]:
                        print(f"     • {commit}")

                print(f"\n   受影响的 {len(update.affected_plugins)} 个插件:")
                for plugin in update.affected_plugins:
                    print(f"     - {plugin.name}")

                print(f"\n   更新命令:")
                print(f"   cd {self.plugins_dir}/marketplaces/{update.name} && git pull")
                print()
        else:
            print("\n✅ 所有插件都是最新版本！")

        print("=" * 60)

    def to_json(self) -> Dict:
        """导出为JSON"""
        return {
            "summary": {
                "local_skills": len(self.local_skills),
                "installed_plugins": len(self.installed_plugins),
                "marketplaces_need_update": sum(
                    1 for m in self.marketplace_updates
                    if m.status == UpdateStatus.UPDATE_AVAILABLE
                ),
                "timestamp": datetime.now().isoformat()
            },
            "local_skills": [
                {
                    "name": s.name,
                    "type": s.type,
                    "source": s.source,
                    "is_broken": s.is_broken
                }
                for s in self.local_skills
            ],
            "installed_plugins": [
                {
                    "name": p.name,
                    "marketplace": p.marketplace,
                    "version": p.version,
                    "installed_at": p.installed_at
                }
                for p in self.installed_plugins
            ],
            "marketplace_updates": [
                {
                    "name": m.name,
                    "repo": m.repo,
                    "local_commit": m.local_commit,
                    "remote_commit": m.remote_commit,
                    "status": m.status.value,
                    "affected_plugins_count": len(m.affected_plugins),
                    "commits_behind": m.commits_behind
                }
                for m in self.marketplace_updates
            ]
        }


@dataclass
class SkillUsage:
    """Skill使用记录"""
    name: str
    marketplace: str
    last_used: str
    use_count: int


class SkillUsageTracker:
    """Skill使用追踪器"""

    def __init__(self, claude_dir: Optional[Path] = None):
        self.claude_dir = claude_dir or Path.home() / ".claude"
        self.history_file = self.claude_dir / "skills-usage.json"
        self.usage_history: Dict[str, Dict] = {}
        self._load_history()

    def _load_history(self):
        """加载使用历史"""
        if self.history_file.exists():
            try:
                self.usage_history = json.loads(self.history_file.read_text())
            except (json.JSONDecodeError, IOError):
                self.usage_history = {}
        else:
            self.usage_history = {}

    def _save_history(self):
        """保存使用历史"""
        self.history_file.parent.mkdir(parents=True, exist_ok=True)
        self.history_file.write_text(
            json.dumps(self.usage_history, indent=2, ensure_ascii=False)
        )

    def record_usage(self, skill_name: str, marketplace: str = "unknown"):
        """记录skill使用"""
        key = f"{skill_name}@{marketplace}"

        if key not in self.usage_history:
            self.usage_history[key] = {
                "name": skill_name,
                "marketplace": marketplace,
                "first_used": datetime.now().isoformat(),
                "last_used": datetime.now().isoformat(),
                "use_count": 0
            }

        self.usage_history[key]["last_used"] = datetime.now().isoformat()
        self.usage_history[key]["use_count"] += 1
        self._save_history()

        return self.usage_history[key]

    def get_top_skills(self, limit: int = 10) -> List[SkillUsage]:
        """获取最常用的skills"""
        skills = []
        for key, data in self.usage_history.items():
            skills.append(SkillUsage(
                name=data["name"],
                marketplace=data["marketplace"],
                last_used=data["last_used"],
                use_count=data["use_count"]
            ))

        return sorted(skills, key=lambda x: x.use_count, reverse=True)[:limit]

    def get_recent_skills(self, limit: int = 10) -> List[SkillUsage]:
        """获取最近使用的skills"""
        skills = []
        for key, data in self.usage_history.items():
            skills.append(SkillUsage(
                name=data["name"],
                marketplace=data["marketplace"],
                last_used=data["last_used"],
                use_count=data["use_count"]
            ))

        return sorted(skills, key=lambda x: x.last_used, reverse=True)[:limit]

    def print_my_skills(self):
        """打印我的常用skills"""
        top_skills = self.get_top_skills(15)
        recent_skills = self.get_recent_skills(10)

        print("=" * 60)
        print("⭐ 我的常用 Skills")
        print("=" * 60)

        if not top_skills:
            print("\n📝 还没有使用记录")
            print("\n💡 提示：使用技能时会自动记录使用历史")
            print("   或者手动记录: python3 check_skills.py --record <skill-name>")
        else:
            print(f"\n🔥 最常用 (Top {len(top_skills)})")
            print("-" * 60)

            for i, skill in enumerate(top_skills, 1):
                last_used = datetime.fromisoformat(skill.last_used).strftime("%Y-%m-%d %H:%M")
                print(f"{i:2}. {skill.name}")
                print(f"    来源: {skill.marketplace}")
                print(f"    使用次数: {skill.use_count}")
                print(f"    最后使用: {last_used}")
                print()

            print("\n🕐 最近使用")
            print("-" * 60)

            for i, skill in enumerate(recent_skills[:10], 1):
                last_used = datetime.fromisoformat(skill.last_used).strftime("%m-%d %H:%M")
                print(f"{i:2}. {skill.name} ({skill.marketplace}) - {last_used}")

        print("\n" + "=" * 60)
        print(f"💾 数据文件: {self.history_file}")
        print("=" * 60)


def main():
    """主函数"""
    import argparse

    parser = argparse.ArgumentParser(description="Claude Skills Checker")
    parser.add_argument("--local", action="store_true", help="仅检查本地skills")
    parser.add_argument("--plugins", action="store_true", help="仅检查插件")
    parser.add_argument("--update", nargs="?", const="all", help="更新marketplace")
    parser.add_argument("--json", action="store_true", help="输出JSON格式")
    parser.add_argument("--my-skills", action="store_true", help="显示我的常用skills")
    parser.add_argument("--record", type=str, metavar="SKILL", help="记录使用的skill")
    parser.add_argument("--marketplace", type=str, default="unknown", help="指定skill的marketplace (配合--record使用)")
    parser.add_argument("--claude-dir", type=Path, help="Claude配置目录路径")

    args = parser.parse_args()

    # 处理 --my-skills
    if args.my_skills:
        tracker = SkillUsageTracker(args.claude_dir)
        tracker.print_my_skills()
        return

    # 处理 --record
    if args.record:
        tracker = SkillUsageTracker(args.claude_dir)
        result = tracker.record_usage(args.record, args.marketplace)
        print(f"✅ 已记录: {result['name']} (来源: {result['marketplace']})")
        print(f"   使用次数: {result['use_count']}")
        print(f"   最后使用: {result['last_used']}")
        return

    checker = SkillsChecker(args.claude_dir)

    if args.local:
        checker.scan_local_skills()
        checker.print_report()
    elif args.plugins:
        checker.scan_installed_plugins()
        checker.check_marketplace_updates()
        checker.print_report()
    elif args.update:
        checker.check_all()
        if args.update == "all":
            for update in checker.marketplace_updates:
                if update.status == UpdateStatus.UPDATE_AVAILABLE:
                    checker.update_marketplace(update.name)
        else:
            checker.update_marketplace(args.update)
    else:
        checker.check_all()

        if args.json:
            print(json.dumps(checker.to_json(), indent=2, ensure_ascii=False))
        else:
            checker.print_report()


if __name__ == "__main__":
    main()
