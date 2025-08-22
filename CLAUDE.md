# n8n-MCP Integration

## Quick Commands

### Start n8n-MCP Connection
```bash
# 推薦使用自定義斜線命令
/n8n-mcp

# 或使用傳統 npm 方式
npm run n8n-mcp
```

This command launches the n8n-MCP integration and connects Claude Code to your n8n platform.

## Custom Slash Commands

Available slash commands in Claude Code:
- `/n8n-mcp` - 一鍵啟動 n8n-MCP 連接器

## Features

- 📁 **智能工作流管理** - 自動化 JSON 工作流文件組織和歸檔
- 🤖 **專業 MCP AI 助手** - 整合 535+ n8n 節點的完整知識庫
- ⚡ **一鍵啟動** - 使用 `/n8n-mcp` 斜線命令快速啟動
- 🔧 **全域指令** - 在任何目錄都能執行管理指令

## 工作流開發規範

### 默認工作目錄
**重要**: 當您執行 `/n8n-mcp` 指令後，所有新建的工作流檔案都應該自動放置在 `workflows/current/` 目錄中。

### 檔案組織結構
- `workflows/templates/` - 工作流基礎模板
- `workflows/current/` - 當前開發中的工作流 
- `workflows/complete/` - 已完成穩定的工作流
- `workflows/archive/` - 舊版本或已棄用的工作流
- `workflows/backup/` - 重要工作流的備份檔案

### 開發生命週期
```
templates/ → current/ → complete/ → archive/
                ↓
            backup/ (跨階段備份)
```

### 開發指導原則
1. 所有新工作流預設存放在 `workflows/current/` 
2. 工作流完成穩定後移至 `workflows/complete/`
3. 工作流命名使用描述性名稱，如 `voice-to-calendar-workflow.json`
4. 測試檔案與工作流放在同一目錄便於管理