#!/usr/bin/env node

/**
 * Dev Loop - 自动迭代调度器（跨平台版本）
 *
 * 使用方法：
 * 1. 复制到你的项目目录: cp loop.sample.js loop.js
 * 2. 确保 tasks.md 文件存在
 * 3. 运行: node loop.js [--max N]
 *    或添加执行权限后直接运行: chmod +x loop.js && ./loop.js
 *
 * 参数说明：
 *   --max N         设置最大迭代次数（默认：无限循环，直到检测到完成信号）
 *
 * 完成信号：
 *   当 Claude 输出包含 <promise>COMPLETE</promise> 时，循环自动结束
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ============================================
// 命令行参数解析
// ============================================

function parseArguments() {
  const args = process.argv.slice(2);

  // 查找 --max 参数
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--max' && args[i + 1]) {
      const max = parseInt(args[++i], 10);
      if (max > 0) {
        return max;
      }
    }
  }

  // 默认：无限循环，直到检测到完成信号
  return null;
}

const maxIterations = parseArguments();

// ============================================
// 文件路径配置
// ============================================

const SCRIPT_DIR = __dirname;
const PROMPT_FILE = path.join(SCRIPT_DIR, 'CLAUDE.md');
const PROGRESS_FILE = path.join(SCRIPT_DIR, 'progress.txt');

// ============================================
// ANSI 颜色代码
// ============================================

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
  red: '\x1b[31m'
};

// 彩色输出函数
function logGreen(text) {
  console.log(`${colors.green}${text}${colors.reset}`);
}

function logYellow(text) {
  console.log(`${colors.yellow}${text}${colors.reset}`);
}

function logCyan(text) {
  console.log(`${colors.cyan}${text}${colors.reset}`);
}

function logRed(text) {
  console.log(`${colors.red}${text}${colors.reset}`);
}

// ============================================
// 进度文件管理
// ============================================

function initProgressFile() {
  const content = `# Dev Loop Progress Log
Started: ${new Date().toISOString()}
---
`;
  fs.writeFileSync(PROGRESS_FILE, content);
}

function ensureProgressFile() {
  if (!fs.existsSync(PROGRESS_FILE)) {
    initProgressFile();
  }
}

// ============================================
// 任务统计
// ============================================

function countTasks() {
  if (!fs.existsSync('tasks.md')) {
    return { todoCount: 0, doneCount: 0 };
  }

  const content = fs.readFileSync('tasks.md', 'utf-8');
  const lines = content.split('\n');

  let todoCount = 0;
  let doneCount = 0;

  for (const line of lines) {
    if (/^-\s\[\s\]/.test(line.trim())) {
      todoCount++;
    } else if (/^-\s\[x\]/.test(line.trim())) {
      doneCount++;
    }
  }

  return { todoCount, doneCount };
}

// ============================================
// 工具函数
// ============================================

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function formatDuration(ms) {
  const seconds = Math.floor(ms / 1000);
  const minutes = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${minutes}分${secs}秒`;
}

function detectCompletionSignal(output) {
  return output.includes('<promise>COMPLETE</promise>');
}

// ============================================
// 主函数
// ============================================

async function main() {
  // 确保进度文件存在
  ensureProgressFile();

  // ⚠️ 强制检查 caution.md
  const CAUTION_FILE = path.join(SCRIPT_DIR, 'caution.md');
  if (!fs.existsSync(CAUTION_FILE)) {
    logRed('╔════════════════════════════════════════════════════════╗');
    logRed('║  ⚠️  警告：caution.md 不存在                           ║');
    logRed('╚════════════════════════════════════════════════════════╝');
    console.log('');
    logRed('正在创建默认 caution.md 模板...');
    console.log('');

    const defaultCaution = `# ⚠️ 开发注意事项

## 强制规则

在此文件中添加开发过程中必须遵守的规则。这些规则将在每次 dev-flow 启动时显示。

## 示例规则

- 禁止未测试就标记任务完成
- 禁止直接修改核心配置文件
- 禁止提交包含 console.log 的代码
- 所有 API 变更必须更新文档

---
请根据项目需求修改上述内容。
`;

    fs.writeFileSync(CAUTION_FILE, defaultCaution);
    logGreen('✅ 已创建 caution.md');
    console.log('');
    logYellow('⚠️  请根据项目需求编辑此文件，添加必须遵守的规则。');
    console.log('');
  }

  // 读取并显示 caution.md
  const cautionContent = fs.readFileSync(CAUTION_FILE, 'utf-8');
  logRed('╔════════════════════════════════════════════════════════╗');
  logRed('║  ⚠️  注意事项 (caution.md)                              ║');
  logRed('╚════════════════════════════════════════════════════════╝');
  console.log('');
  console.log(cautionContent);
  console.log('');
  logRed('⚠️  以上规则必须严格遵守！');
  console.log('');

  logGreen('╔════════════════════════════════════════════════════════╗');
  logGreen('║     Dev Loop - 自动迭代调度器                           ║');
  logGreen('╚════════════════════════════════════════════════════════╝');
  console.log('');

  if (maxIterations) {
    logCyan(`最大迭代次数: ${maxIterations}`);
  } else {
    logCyan('模式: 无限循环（直到检测到完成信号）');
  }
  console.log('');

  // 检查 tasks.md 是否存在
  if (!fs.existsSync('tasks.md')) {
    logYellow('⚠️  警告：tasks.md 不存在');
    console.log('   将继续运行，但无法统计任务进度');
    console.log('');
  }

  // 初始统计
  const { todoCount, doneCount } = countTasks();

  if (fs.existsSync('tasks.md')) {
    logYellow('📊 当前状态：');
    console.log(`   待处理：${todoCount} 个`);
    console.log(`   已完成：${doneCount} 个`);
    console.log('');

    if (todoCount === 0) {
      logGreen('🎉 所有任务已完成！');
      process.exit(0);
    }
  }

  // 迭代循环
  let completed = false;
  let iteration = 0;

  while (true) {
    iteration++;

    // 检查是否超过最大迭代次数
    if (maxIterations && iteration > maxIterations) {
      console.log('');
      logYellow(`⚠️  Dev Loop 已达到最大迭代次数 (${maxIterations}) 但未完成所有任务`);
      logCyan(`📝 查看进度文件：${PROGRESS_FILE}`);
      process.exit(1);
    }

    console.log('');
    logGreen('===============================================================');
    if (maxIterations) {
      logGreen(`  迭代 ${iteration} / ${maxIterations}`);
    } else {
      logGreen(`  迭代 #${iteration}`);
    }
    logGreen('===============================================================');
    console.log('');

    // 记录开始时间
    const startTime = Date.now();

    let output = '';
    let commandOutput = '';

    try {
      // 使用 Claude Code 调用 dev-flow
      if (fs.existsSync(PROMPT_FILE)) {
        // 优先使用 CLAUDE.md 文件
        commandOutput = execSync(`claude --dangerously-skip-permissions --print < "${PROMPT_FILE}"`, {
          encoding: 'utf-8',
          stdio: 'inherit'  // 关键：实时输出到终端
        });
      } else {
        // 备用：直接调用 dev-flow 技能
        commandOutput = execSync('claude --dangerously-skip-permissions "使用 dev-flow 技能处理下一个任务"', {
          encoding: 'utf-8',
          stdio: 'inherit'  // 关键：实时输出到终端
        });
      }
      output = commandOutput || '';
    } catch (error) {
      // 关键：无论命令是否成功，都继续循环
      // 捕获可能的输出信息
      output = error.stdout || error.stderr || '';
      // 不抛出错误，确保循环继续
      console.log('');
    }

    // 记录结束时间
    const endTime = Date.now();
    const duration = endTime - startTime;

    console.log('');
    logGreen(`✓ 迭代 #${iteration} 完成`);
    console.log(`  耗时：${formatDuration(duration)}`);
    console.log('');

    // 检查完成信号
    if (detectCompletionSignal(output)) {
      console.log('');
      logGreen('===============================================================');
      logGreen('🎉 Dev Loop 已完成所有任务！');
      logGreen(`  在第 ${iteration} 次迭代完成`);
      logGreen('===============================================================');
      completed = true;
      break;
    }

    // 更新统计
    const stats = countTasks();
    const currentTodo = stats.todoCount;
    const currentDone = stats.doneCount;

    if (fs.existsSync('tasks.md')) {
      logYellow('📊 当前进度：');
      console.log(`   待处理：${currentTodo} 个`);
      console.log(`   已完成：${currentDone} 个`);
      console.log('');
    }

    console.log(`迭代 ${iteration} 完成。继续...`);
    console.log('');

    // 短暂暂停
    await sleep(2000);
  }

  // 最终状态
  console.log('');
  logGreen(`✨ 成功完成所有任务（共 ${iteration} 次迭代）`);
  process.exit(0);
}

// 运行主函数
main().catch(error => {
  console.error('发生错误：', error.message);
  process.exit(1);
});
