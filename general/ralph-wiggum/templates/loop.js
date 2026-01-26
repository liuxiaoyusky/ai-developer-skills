#!/usr/bin/env node
const fs = require('fs');
const { execSync } = require('child_process');

let iteration = 0;
while (true) {
  iteration++;
  console.log(`\n=== Iteration ${iteration} ===\n`);

  const tasks = fs.readFileSync('TASKS.md', 'utf8');

  if (!tasks.includes('- [ ]')) {
    console.log('✅ All tasks complete!');
    break;
  }

  execSync('claude -p "Implement the next incomplete task in TASKS.md. Update the checkbox to [x] when done."', {
    stdio: 'inherit',
    shell: true
  });
}
