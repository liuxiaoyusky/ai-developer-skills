# Changelog

All notable changes to the `dev-verify` skill will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-02-05

### Added

#### Core Features
- **真实测试执行** - 通过 Bash 工具执行实际测试（非 AI 模拟）
- **Linus Torvalds 5层代码审查** - 测试前自动应用代码审查框架
- **自动测试框架检测** - 支持 Python (pytest), JavaScript/TypeScript (jest/vitest/mocha), Go (go test), Java (JUnit/Maven/Gradle)
- **测试结果自动标记** - 所有结果记录到 `task-details-test.md`
- **失败自动调试** - 测试失败时自动调用 `dev-debug` 技能
- **持续迭代** - 直到所有测试通过才继续

#### Framework Detectors
- `detect-python.sh` - 检测 pytest, unittest, tox
- `detect-javascript.sh` - 检测 jest, vitest, mocha, ava, tape, jasmine
- `detect-go.sh` - 检测 go test
- `detect-java.sh` - 检测 JUnit, Maven, Gradle

#### Templates
- `task-details-test.template.md` - 完整测试方案模板，包含：
  - Linus 5层代码审查部分
  - 5个测试类别（单元、集成、启动、行为、性能）
  - Debug 会话记录格式
  - 测试汇总表
  - 验收标准

#### Integration
- **dev-flow Step 4 集成** - 自动替换手动测试执行
- **dev-debug 自动调用** - 每个失败测试自动触发调试
- **dev-review 框架复用** - 使用已有的 5层代码审查

#### Documentation
- `SKILL.md` - 完整技能定义，包含：
  - 6阶段工作流程
  - 测试框架检测逻辑
  - 错误处理策略
  - 集成协议
  - 详细示例
- `README.md` - 用户文档，包含：
  - 快速开始
  - 支持的框架
  - 故障排除
  - 贡献指南
- `CHANGELOG.md` - 本文件

#### Logging
- `dev-verify.log` - 完整执行日志，包含：
  - START/COMPLETE 标记
  - REVIEW 代码审查记录
  - DETECT 框架检测结果
  - EXECUTE 测试执行记录
  - INVOKE dev-debug 调用记录
  - FIXED 修复完成记录

### Test Commands Support

| Framework | Command |
|-----------|---------|
| pytest | `pytest -v --tb=short` |
| unittest | `python -m unittest` |
| jest | `npm test -- --verbose` |
| vitest | `npm test -- --run` |
| mocha | `npm test` |
| go-test | `go test -v ./...` |
| JUnit (Maven) | `mvn test` |
| JUnit (Gradle) | `gradle test` |

### Error Handling

- 未知框架优雅降级到手动测试说明
- 测试超时处理（5分钟超时）
- 依赖缺失提示和解决方案
- 多层框架检测策略（配置文件 → 依赖 → 文件约定）

### Design Principles

1. 真实执行优先于 AI 模拟
2. dev-flow Step 4 自动激活
3. 测试前代码审查
4. 多层框架检测与优雅降级
5. 单一数据源（task-details-test.md）
6. 每个失败独立调试

---

## [Unreleased]

### Planned Features
- Ruby (RSpec) 支持
- .NET (NUnit, xUnit) 支持
- PHP (PHPUnit) 支持
- Rust (cargo test) 支持
- 并行测试执行
- 测试覆盖率报告
- 性能基准测试
- 可配置超时时间
- 自定义测试命令

---

## Version Convention

- **Major (X.0.0)** - 破坏性变更或重大功能添加
- **Minor (0.X.0)** - 新功能或框架支持
- **Patch (0.0.X)** - Bug 修复或文档更新

---

**End of Changelog**
