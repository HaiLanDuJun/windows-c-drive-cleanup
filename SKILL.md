---
name: windows-c-drive-cleanup
description: Safely analyze and clean Windows C drive space on Windows machines. Use when the user asks to clean C drive, free disk space, remove low-risk caches, inspect disk usage, clean npm/temp/Windows update cache, or plan safe cleanup of Docker, JetBrains, Maven, LM Studio, browser, or developer-tool caches. 适用于 Windows C 盘清理、释放磁盘空间、低风险缓存清理和清理前风险评估。
---

# Windows C Drive Cleanup

## 简介 / Introduction

这是一个面向 Windows 的 C 盘清理 skill，重点帮助 agent 先分析 C 盘空间占用，再按低风险、中风险、高风险分级给出清理方案。它特别适合处理 npm 缓存、临时目录、Windows 更新下载缓存、浏览器缓存、IDE 缓存、Docker 占用、Maven/Gradle 缓存、LM Studio/Ollama 模型目录等常见 C 盘膨胀来源。

This skill helps agents analyze and safely clean Windows C drive space. It prioritizes read-only measurement, risk classification, explicit approval before deletion, and careful handling of developer-tool caches and system-generated data.

## Core Rule

Treat C drive cleanup as a safety-sensitive filesystem task. Start with read-only measurement, separate targets by risk, and ask for explicit approval before any deletion. Never delete personal files, project directories, installed applications, system folders, Docker data, model folders, IDE plugins, or package repositories unless the user explicitly confirms that exact target.

## Workflow

1. Measure current C drive free space:
   - Use `Get-PSDrive C | Select-Object Name,Used,Free`.
   - Use `scripts/measure-c-drive.ps1` for common cache locations.
2. Classify findings:
   - Low risk: user temp, Windows temp, npm cache, browser cache, crash dumps, Windows update download cache when no update is installing.
   - Medium risk: IDE indexes/caches/logs, Maven/Gradle caches, Codex runtimes, generic `.cache` folders. These are reproducible but may slow future work.
   - High risk: Docker data directories, LM Studio/Ollama model folders, Downloads, Desktop, project folders, installed software, `Program Files`, `Windows`, `System32`, user documents.
3. Present a cleanup plan with estimated space and exact paths.
4. Ask for approval for each destructive group. Do not bundle high-risk targets with low-risk cleanup.
5. Run cleanup with `-Execute` only after approval. Otherwise use dry-run output.
6. Re-measure free space and summarize what changed.

## Scripts

Read-only scan:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\measure-c-drive.ps1
```

Low-risk dry run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\clean-low-risk.ps1
```

Low-risk execution after user approval:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\clean-low-risk.ps1 -Execute
```

Optional switches:

- `-SkipWindowsUpdateDownload`: skip `C:\Windows\SoftwareDistribution\Download`.
- `-SkipNpmCache`: skip npm cache.
- `-SkipTemp`: skip temp folders.

## Safety Checks

Before deleting:

- Check running processes when cleaning active tool caches: `Get-Process | Where-Object { $_.ProcessName -match 'idea|jetbrains|docker|node|npm|chrome|msedge' }`.
- Avoid cleaning IDE caches while the IDE is running.
- Avoid cleaning Windows update download cache while Windows Update is downloading, preparing, or installing updates.
- Prefer official commands when available, such as `npm cache clean --force` and `docker system prune`, instead of deleting backing directories manually.

## Docker Guidance

Do not delete `C:\Users\<user>\AppData\Local\Docker` directly. If Docker Desktop is running and the user approves Docker cleanup, use:

```powershell
docker system df
docker system prune
```

Use `docker system prune -a --volumes` only after the user explicitly confirms removal of unused images, build cache, stopped containers, networks, and unused volumes.

## IDE Guidance

For JetBrains directories, do not delete `plugins` or settings. Candidate cleanup targets are usually `index`, `caches`, `log`, `jcef_cache`, `tmp`, `vcs-log`, and similar generated folders. Confirm the IDE is closed first.

## Response Pattern

Report:

- before and after free space;
- paths cleaned;
- paths intentionally skipped and why;
- remaining large targets with risk level.