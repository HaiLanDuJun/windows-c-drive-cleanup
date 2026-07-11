# Windows C Drive Cleanup Skill

## 中文简介

`windows-c-drive-cleanup` 是一个专注于 **Windows C 盘清理** 的 Agent Skill。它用于帮助 AI agent 安全分析 C 盘空间占用，并在清理前区分低风险、中风险和高风险目标。

它适合处理：

- npm 缓存、用户临时目录、Windows 临时目录
- Windows 更新下载缓存
- 浏览器缓存、崩溃转储和错误报告
- JetBrains / IDEA 缓存、索引和日志
- Maven / Gradle / Codex runtimes 等开发工具缓存
- Docker、LM Studio、Ollama 等高风险大目录的清理评估

核心原则：**先只读扫描，再展示清理计划；默认 dry-run；任何删除动作都必须经过用户明确确认。**

## English Introduction

`windows-c-drive-cleanup` is an Agent Skill for safely analyzing and cleaning Windows C drive space. It helps agents measure disk usage, classify cleanup targets by risk, and avoid destructive actions without explicit user approval.

The skill includes reusable PowerShell scripts for read-only scanning and low-risk cleanup. The cleanup script defaults to dry-run mode and only deletes files when called with `-Execute` after approval.

## Files

- `SKILL.md`: runtime instructions for agents.
- `scripts/measure-c-drive.ps1`: read-only C drive usage scan.
- `scripts/clean-low-risk.ps1`: low-risk cleanup script with dry-run by default.
- `agents/openai.yaml`: UI metadata for OpenAI/Codex skill surfaces.

## Example Commands

Read-only scan:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\measure-c-drive.ps1
```

Low-risk dry run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\clean-low-risk.ps1
```

Execute low-risk cleanup after explicit approval:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\clean-low-risk.ps1 -Execute
```