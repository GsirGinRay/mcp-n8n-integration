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

## n8n 工作流開發自動化流程

### 重要指示：當執行 `/n8n-mcp` 指令後的工作流開發規範

當用戶執行 `/n8n-mcp` 指令後，你必須按照以下流程進行工作流開發：

#### 第一步：自動研究和分析
1. **檢查 MCP 中的相似案例**
   - 自動搜尋 `workflows/current/` 中的現有工作流
   - 分析相似功能的節點配置和最佳實踐
   - 參考成功案例的結構模式

2. **查詢 n8n 官方文檔**
   - 使用 WebSearch 工具搜尋 n8n 官方文檔
   - 查詢相關節點的最新參數和配置方法
   - 確認節點的 typeVersion 和正確語法

3. **標準 JSON 格式驗證**
   - 參考現有工作流的 JSON 結構
   - 確保包含必要的字段：name, nodes, connections, settings, staticData
   - 驗證每個節點的 id, name, type, typeVersion, position, parameters

#### 第二步：生成真正的 n8n 工作流
1. **必須生成可直接導入 n8n 的 JSON 檔案**
   - 使用正確的 n8n 節點類型（如 n8n-nodes-base.webhook）
   - 包含正確的 typeVersion
   - 設置正確的 position 座標
   - 建立正確的 connections 結構

2. **節點配置要求**
   - 所有節點必須使用真實存在的 n8n 節點類型
   - parameters 必須符合該節點的實際 API
   - 包含必要的 credentials 配置（如果需要）
   - 設置正確的錯誤處理機制

3. **檔案結構要求**
   ```json
   {
     "name": "工作流名稱",
     "active": false,
     "nodes": [/* 節點陣列 */],
     "connections": {/* 連接配置 */},
     "settings": {},
     "staticData": {},
     "tags": [],
     "triggerCount": 1,
     "updatedAt": "ISO日期",
     "versionId": "版本號"
   }
   ```

#### 第三步：自動化品質保證
1. **工作流驗證**
   - 檢查 JSON 語法正確性
   - 驗證所有節點連接完整
   - 確認沒有遺漏必要參數

2. **檔案命名和組織**
   - 使用描述性檔名，如 `voice-to-calendar-workflow.json`
   - 自動放置在 `workflows/current/` 目錄
   - 生成對應的設置指南 markdown 檔案

3. **測試準備**
   - 提供導入 n8n 的具體步驟
   - 列出需要配置的 credentials
   - 說明測試方法和預期結果

### 禁止行為
❌ **絕對不可以：**
- 生成無法導入 n8n 的偽 JSON 檔案
- 使用不存在的節點類型或參數
- 忽略 MCP 中的現有最佳實踐
- 跳過官方文檔查詢步驟
- 產生不完整的工作流結構

### 成功標準
✅ **工作流開發成功的標準：**
- JSON 檔案可以直接導入 n8n 並運行
- 所有節點配置正確且完整
- 包含適當的錯誤處理機制
- 遵循 n8n 最佳實踐
- 有完整的使用說明和設置指南