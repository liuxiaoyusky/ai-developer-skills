#!/usr/bin/env node

/**
 * Ralph Loop - 自动迭代调度器（跨平台版本）
 *
 * 使用方法：
 * 1. 复制到你的项目目录: cp loop.sample.js loop.js
 * 2. 确保 tasks.md 文件存在
 * 3. 运行: node loop.js
 *    或添加执行权限后直接运行: chmod +x loop.js && ./loop.js
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ANSI 颜色代码
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m'
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

// 解析 tasks.md 统计任务
function countTasks() {
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

// 延迟函数
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// 格式化时间
function formatDuration(ms) {
  const seconds = Math.floor(ms / 1000);
  const minutes = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${minutes}分${secs}秒`;
}

// 主函数
async function main() {
  logGreen('╔════════════════════════════════════════════════════════╗');
  logGreen('║     Ralph Loop - 自动迭代调度器                          ║');
  logGreen('╚════════════════════════════════════════════════════════╝');
  console.log('');

  // 检查 tasks.md 是否存在
  if (!fs.existsSync('tasks.md')) {
    logYellow('❌ 错误：tasks.md 不存在');
    console.log('   请先创建 tasks.md 并添加任务');
    process.exit(1);
  }

  // 初始统计
  let { todoCount, doneCount } = countTasks();

  logYellow('📊 当前状态：');
  console.log(`   待处理：${todoCount} 个`);
  console.log(`   已完成：${doneCount} 个`);
  console.log('');

  if (todoCount === 0) {
    logGreen('🎉 所有任务已完成！');
    process.exit(0);
  }

  // 迭代循环
  let iteration = 0;

  while (true) {
    iteration++;

    logGreen('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    logGreen(`🔄 迭代 #${iteration} 开始`);
    logGreen('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('');

    // 记录开始时间
    const startTime = Date.now();

    try {
      // 调用 Claude CLI 执行 dev-flow
      // 每次调用 = 1 次 dev-flow 执行（5 步闭环）
      execSync('claude --dangerously-skip-permissions "使用 dev-flow 技能处理下一个任务"', {
        stdio: 'inherit',
        shell: true
      });
    } catch (error) {
      // Claude 返回非零退出码时继续循环
      console.log('');
    }

    // 记录结束时间
    const endTime = Date.now();
    const duration = endTime - startTime;

    console.log('');
    logGreen(`✓ 迭代 #${iteration} 完成`);
    console.log(`  耗时：${formatDuration(duration)}`);
    console.log('');

    // 更新统计
    const stats = countTasks();
    todoCount = stats.todoCount;
    doneCount = stats.doneCount;

    logYellow('📊 当前进度：');
    console.log(`   待处理：${todoCount} 个`);
    console.log(`   已完成：${doneCount} 个`);
    console.log('');

    // 检查是否还有待处理任务
    if (todoCount === 0) {
      logGreen('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      logGreen('🎉 所有任务已完成！');
      logGreen('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      break;
    }

    // 短暂暂停
    logYellow('⏳ 等待 2 秒后继续...');
    await sleep(2000);
    console.log('');
  }

  console.log('');
  logGreen(`✨ 总共完成 ${iteration} 次迭代`);
  logCyan('📝 查看详细日志：cat dev-flow.log');
}

// 运行主函数
main().catch(error => {
  console.error('发生错误：', error.message);
  process.exit(1);
});
