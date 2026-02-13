# Task Result

## 状态: [SUCCESS | ROLLBACK | FAILED]

## 任务: [子任务标题]

## 时间: YYYY-MM-DD HH:mm

---

## 变更摘要

<!-- 列出本次实现中修改和新增的文件 -->

- [修改/新增] [文件路径]: [做了什么]
- [修改/新增] [文件路径]: [做了什么]

## 建议 Commit Message

<!-- 遵循 conventional commits 格式 -->
<!-- feat(scope): 新功能 | fix(scope): 修复 | refactor(scope): 重构 -->

[type]([scope]): [description]

## 测试结果

- [测试类型]: [通过数/总数] [passed/failed]
- [测试类型]: [通过数/总数] [passed/failed]

---

<!-- 以下仅在 ROLLBACK 或 FAILED 时填写 -->

## 失败原因

<!-- 汇总 debug-log.md 中的关键失败信息 -->

[debug N次均未能解决的原因汇总]

## 建议方向

<!-- 为下次重试提供不同的实现路径建议 -->

[下次尝试时建议采用的不同方案]
