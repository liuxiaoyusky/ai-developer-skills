# Ralph Loop - Windows 示例脚本
# 使用方法：
# 1. 复制到你的项目目录: copy loop.sample.ps1 loop.ps1
# 2. 确保 TASKS.md 文件存在
# 3. 运行: .\loop.ps1

$iteration = 0
while ($true) {
    $iteration++
    Write-Host ""
    Write-Host "=== Iteration $iteration ==="
    Write-Host ""

    $tasks = Get-Content "TASKS.md" -Raw -ErrorAction SilentlyContinue
    if ($tasks -notmatch '\[ \]') {
        Write-Host "✅ All tasks complete!"
        break
    }

    claude -p "Implement the next incomplete task in TASKS.md. Update the checkbox to [x] when done."
}
