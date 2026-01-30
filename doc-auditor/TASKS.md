# Project: Doc Auditor 第一性原理重构

## 目标

将 doc-auditor 从"静态分析工具"升级为"AI 驱动的智能文档审计系统"，基于第一性原理重新设计架构。

## 设计文档

详见: `~/.claude/plans/glowing-wibbling-pie.md`

## Tasks

### Phase 1: 模块化重构基础
- [ ] 创建 `doc_auditor/` 包结构 - 验收：`doc_auditor/__init__.py` 可以正常 import
- [ ] 实现 `scanner.py` 文档扫描器 - 验收：单元测试通过，能扫描目录并过滤 .md 文件
- [ ] 迁移 `collect_context.py` 到 `collector.py` - 验收：保持原有功能，单元测试通过
- [ ] 添加使用证据收集到 `collector.py` - 验收：能收集文件访问时间和文档间引用
- [ ] 编写 `pyproject.toml` 包配置 - 验收：可以用 `pip install -e .` 安装

### Phase 2: AI 语义分析
- [ ] 实现 `llm_client.py` Claude API 客户端 - 验收：能成功调用 Claude API 并获取响应
- [ ] 实现 `prompts.py` 提示词模板 - 验收：包含分类、相关性评估、关键点提取模板
- [ ] 实现 `fallback.py` 规则引擎降级 - 验收：API 不可用时自动切换到规则引擎
- [ ] 实现 `classifier.py` 文档分类器 - 验收：LLM 和规则引擎两种模式都能正确分类
- [ ] 添加 AI 分类单元测试 - 验收：测试覆盖率达到 80%

### Phase 3: 价值评分系统
- [ ] 实现 `scorer.py` 价值评分器 - 验收：能计算使用、准确度、维护三个维度分数
- [ ] 实现使用分数计算 - 验收：访问频率 + 被引用数 + 最近访问时间
- [ ] 实现准确度分数计算 - 验收：根据文档类型和问题数量动态评分
- [ ] 实现维护分数计算 - 验收：基于 Git 历史的活跃度评分
- [ ] 编写评分器单元测试 - 验收：测试边界情况和各种组合

### Phase 4: 智能审计决策
- [ ] 实现 `auditor.py` 审计决策器 - 验收：基于分数和类型给出 6 种操作建议
- [ ] 实现新的决策树逻辑 - 验收：符合第一性原理决策表
- [ ] 集成分类、评分、审计流程 - 验收：端到端流程能正常运行
- [ ] 添加集成测试 - 验收：测试真实文档的审计流程

### Phase 5: 分类归档系统
- [ ] 实现 `archive_manager.py` 归档管理器 - 验收：能按时间和类型归档文档
- [ ] 实现 `organizer.py` 分类组织器 - 验收：生成正确的归档路径结构
- [ ] 实现归档元数据文件 - 验收：归档时创建 `.archive-metadata.json`
- [ ] 添加归档恢复功能 - 验收：能从归档恢复到原位置
- [ ] 测试归档目录结构 - 验收：符合 `archive/YYYY-MM/doc-type/` 规范

### Phase 6: CLI 接口
- [ ] 实现 `cli/scan.py` 扫描命令 - 验收：`doc-audit scan <dir>` 能正常工作
- [ ] 实现 `cli/audit.py` 审计命令 - 验收：`doc-audit audit <doc>` 能输出审计结果
- [ ] 实现 `cli/archive.py` 归档命令 - 验收：`doc-audit archive <doc>` 能正确归档
- [ ] 重写旧脚本为 CLI 包装器 - 验收：保持向后兼容，旧脚本仍可使用
- [ ] 添加 `--help` 和使用文档 - 验收：每个命令都有清晰的帮助信息

### Phase 7: 更新文档和工作流
- [ ] 重写 `SKILL.md` 工作流程 - 验收：包含新的 CLI 命令和 AI 能力说明
- [ ] 更新决策表和分类标准 - 验收：反映新的 6 种操作和评分机制
- [ ] 更新 `README.md` 使用说明 - 验收：包含安装、配置、使用示例
- [ ] 更新 `patterns.md` 过时模式 - 验收：添加 AI 语义分析相关的模式
- [ ] 添加环境变量配置文档 - 验收：说明 `CLAUDE_API_KEY` 等配置项

### Phase 8: 测试和优化
- [ ] 编写端到端测试 - 验收：测试完整的审计和归档流程
- [ ] 性能优化 - 验收：处理 100+ 文档时 < 30 秒
- [ ] 添加错误处理和日志 - 验收：异常情况有清晰的错误信息
- [ ] 编写迁移指南 - 验收：旧用户能顺利升级
- [ ] 发布 v2.0.0 版本 - 验收：更新版本号和 changelog

---

## Validation

```bash
# 单元测试
pytest doc_auditor/tests/ -v --cov=doc_auditor --cov-report=html

# 类型检查
mypy doc_auditor/

# Lint
flake8 doc_auditor/

# CLI 测试
doc-audit scan . --output manifest.json
doc-audit audit docs/README.md
doc-audit archive docs/old-report.md --dry-run

# 包安装测试
pip install -e .
python -c "import doc_auditor; print(doc_auditor.__version__)"

# 集成测试（可选）
cd tests/fixtures/sample-project
doc-audit scan . | doc-audit batch-audit --dry-run
```

## 环境变量

```bash
# Claude API 配置
export CLAUDE_API_KEY="sk-ant-xxx"
export CLAUDE_MODEL="claude-3-5-sonnet-20241022"  # 可选

# 降级配置
export DOC_AUDITOR_FALLBACK="rules"  # llm | rules | hybrid
```

## 关键设计原则

1. **向后兼容**：旧脚本继续工作，用户可以渐进式迁移
2. **降级优雅**：API 不可用时自动切换到规则引擎
3. **测试驱动**：每个模块都有对应的单元测试
4. **文档同步**：代码和文档同步更新
5. **第一性原理**：每个模块都从基本真理出发设计

---

**Format**: `- [ ]` incomplete, `- [x]` complete. Loop stops when all are `[x]`.
**Keep it minimal** - 每个任务聚焦单一职责，完成后删除。
