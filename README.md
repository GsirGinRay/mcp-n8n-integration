# 🚀 n8n 工作流管理工具 + 專業 MCP 整合

一個簡潔高效的 n8n 工作流管理系統，整合專業級 MCP AI 助手，讓你的 n8n 開發更智能、更有序。

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Node.js](https://img.shields.io/badge/node.js-18+-green.svg)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)

## 📖 教學影片

🎥 **完整教學影片**: [即將推出]

## ✨ 特色功能

- 📁 **智能工作流管理** - 自動化 JSON 工作流文件組織和歸檔
- 🤖 **專業 MCP AI 助手** - 整合 535+ n8n 節點的完整知識庫
- 🔧 **全域指令** - 在任何目錄都能執行管理指令
- 📱 **跨平台支援** - Windows、Linux、macOS
- 🎯 **簡潔設計** - 專注核心功能，去除冗余
- 🔒 **安全保護** - 敏感配置文件自動排除

## 🎯 適用場景

- **n8n 開發者** - 高效管理和組織工作流文件
- **AI + 自動化愛好者** - 體驗專業級 MCP AI 助手
- **企業團隊** - 標準化工作流開發和協作流程
- **教學和學習** - 結合 AI 助手的工作流設計教學

## 🚀 快速開始

### 前置需求

- Node.js 18+ 
- n8n 實例 (本地或雲端)
- Claude Desktop (使用 MCP AI 助手)

### 一次性設置

1. **克隆專案**
   ```bash
   git clone https://github.com/GsirGinRay/mcp-n8n-integration.git
   cd mcp-n8n-integration
   ```

2. **安裝依賴**
   ```bash
   npm install
   ```

3. **Claude Code 準備就緒**
   ```bash
   # 無需額外設置，直接在 Claude Code 中使用
   # MCP 已自動配置完成
   ```

4. **配置 MCP 連接**
   ```bash
   # 複製配置模板
   cp claude-desktop-config.example.json claude-desktop-config.json
   
   # 編輯配置文件，填入你的 API Key
   # 將 "your_n8n_api_key_here" 替換為真實的 API Key
   # 將 "https://your-n8n-instance.com" 替換為你的 n8n 網址
   ```

5. **開始使用**
   ```bash
   # 啟動 n8n-MCP 連接器
   npm n8n-mcp
   ```

### 日常使用

```bash
# 🚀 啟動 n8n-MCP 連接器
npm n8n-mcp

# 🤖 直接與 AI 助手對話創建工作流
💬 "幫我設計一個 LINE 聊天機器人工作流"
💬 "推薦處理 CSV 數據的 n8n 節點"  
💬 "這個工作流 JSON 有什麼問題？[貼上JSON]"
💬 "如何優化工作流性能？"

# 🧠 MCP AI 助手自動功能
# - 每次使用指令時自動載入 535+ n8n 節點知識
# - 在 Claude Desktop 中獲得專業工作流設計建議
# - 智能節點組合推薦和最佳實踐指導
```

## 📁 專案結構

```
mcp-n8n-integration/
├── 📄 package.json              # 專案配置和依賴
├── 📄 n8n-mcp                   # 🚀 核心啟動指令 (Claude Code)
├── 📄 claude-desktop-config.example.json # MCP 配置模板
├── 📄 claude-desktop-config.json # MCP 連接配置 (需自行創建)
├── 📁 workflows/                # 工作流管理中心
│   ├── 📁 current/              # 🔨 開發中的工作流
│   ├── 📁 archive/              # 📦 已完成的工作流
│   ├── 📁 templates/            # 📋 工作流模板
│   └── 📁 backup/               # 💾 自動備份
└── 📄 .gitignore                # 安全保護設定
```

## 🔧 指令參考

### Claude Code 指令
| 指令 | 功能 |
|------|------|
| `npm n8n-mcp` | 🚀 **啟動 n8n-MCP 連接器，自動連接 MCP 和 n8n 平台** |

### AI 助手功能 (自動啟用)
| 功能 | 說明 |
|------|------|
| 🤖 **智能問答** | 直接詢問 n8n 相關問題，獲得專業建議 |
| 📚 **535+ 節點知識** | 完整的 n8n 節點參數和使用方法 |
| 🔧 **工作流設計** | AI 協助設計和優化工作流結構 |
| 🐛 **錯誤診斷** | 分析工作流 JSON 找出問題和改進建議 |
| 💡 **最佳實踐** | 提供行業最佳實踐和性能優化建議 |

### 支援的工作流類型
| 類型 | 說明 | MCP 建議節點 |
|------|------|--------------|
| `chatbot` | 聊天機器人 | Webhook, AI Agent, HTTP Request |
| `self-learning` | 自學習AI | AI Agent, Database, Analytics |
| `api` | API整合 | HTTP Request, Function, Error Handling |
| `automation` | 自動化任務 | Schedule, Multiple APIs, Notifications |
| `data-processing` | 數據處理 | Database, Transform, Validation |
| `custom` | 自定義 | 基於需求智能推薦 |

## 🛠️ 配置說明

### 環境變數 (.env)

```env
# n8n 連接配置
N8N_BASE_URL=https://your-n8n-instance.com
N8N_API_KEY=your_n8n_api_key

# 應用設定
LOG_LEVEL=info
DEBUG_MODE=false
```

### 專業 MCP AI 助手功能

- **535+ n8n 節點知識** - 完整的節點參數和使用方法
- **AI 工作流設計** - 智能設計建議和最佳實踐  
- **工作流驗證** - 自動檢測配置錯誤和優化建議
- **實時問答** - 在 Claude Desktop 中直接獲得專業解答
- **安全檢查** - 工作流安全性分析和建議
- **API 整合** - 直接連接你的 n8n 實例進行實時操作

> 由 [czlonkowski/n8n-mcp](https://github.com/czlonkowski/n8n-mcp) 提供專業支援

## 💻 Claude Code 使用指南

### 快速連接 MCP 和 n8n

在任何目錄中，只需輸入：
```
npm n8n-mcp
```

這個指令會：
- ✅ 檢查 MCP 配置狀態
- 🤖 初始化 n8n 專業助手 (535+ 節點知識)  
- 🔌 測試 n8n 平台連接
- 📋 顯示可用功能和使用說明

### 直接 AI 問答

配置完成後，你可以直接在 Claude Code 中詢問：
- 💬 "幫我設計一個 LINE 聊天機器人工作流"
- 💬 "推薦處理 CSV 數據的 n8n 節點"
- 💬 "這個工作流 JSON 有什麼問題嗎？[貼上你的JSON]"
- 💬 "如何優化這個 n8n 工作流的性能？"

MCP 助手會自動提供專業建議和 535+ 節點的完整知識！

## 🎓 教學範例

### 範例1：Claude Code 工作流程

```bash
# 1. 啟動 n8n-MCP 連接器
npm n8n-mcp

# 2. 直接詢問 AI 助手
💬 "幫我設計一個自動發送郵件通知的工作流"

# 3. 獲得專業建議和具體節點推薦
# AI 會推薦: Webhook → Email → Slack 等節點組合

# 4. 讓 AI 助手指導你創建實際的 n8n 工作流
```

### 範例2：工作流文件管理

```bash
# 1. 啟動 n8n-MCP 連接器
npm n8n-mcp

# 2. 直接在 Claude Code 中管理文件
💬 "幫我分析 workflows/current/ 中的工作流文件"
💬 "這些工作流有什麼可以優化的地方？"
💬 "建議如何組織這些工作流？"
```

### 範例3：AI 助手實際應用

```
在 Claude Code 中直接詢問：

💬 "幫我設計一個發送郵件通知的 n8n 工作流"
💬 "這個工作流 JSON 有什麼問題嗎？[貼上你的 JSON]"
💬 "推薦適合處理 CSV 數據的 n8n 節點"
💬 "如何優化這個工作流的性能？"
```

## 🔒 安全提醒

⚠️ **重要：保護你的 API Key**
- `claude-desktop-config.json` 包含敏感的 API Key，已被加入 `.gitignore`
- 請勿將此文件推送到 GitHub 或其他公開平台
- 如果意外推送了 API Key，請立即到 n8n 平台重新生成新的 API Key

✅ **安全最佳實踐**
- 使用 `claude-desktop-config.example.json` 模板創建配置
- 定期更換 API Key
- 不要在截圖或日誌中暴露 API Key

## 🚨 故障排除

### 常見問題

**Q: npm n8n-mcp 指令無反應**
```bash
# 確認已全域安裝
npm n8n-mcp

# 檢查 MCP 配置文件
claude-desktop-config.json
```

**Q: 無法連接到 MCP 助手**
1. 確認 Claude Code 已正確安裝
2. 檢查 claude-desktop-config.json 配置
3. 重新啟動 Claude Code

**Q: MCP AI 助手無法連接**
- 確保 Claude Desktop 已安裝
- 檢查 `claude-desktop-config.json` 配置
- 運行 `mcp-setup` 重新設置

**Q: n8n 連接失敗**
- 檢查 `.env` 中的 n8n URL 和 API 密鑰
- 確認 n8n 實例正在運行
- 測試 API 密鑰權限

## 🤝 貢獻指南

1. Fork 此專案
2. 創建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交變更 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 開啟 Pull Request

## 📝 授權條款

本專案使用 MIT 授權條款 - 詳見 [LICENSE](LICENSE) 文件

## 🙏 致謝

- [n8n](https://n8n.io/) - 強大的工作流自動化平台
- [czlonkowski/n8n-mcp](https://github.com/czlonkowski/n8n-mcp) - 專業級 n8n MCP AI 助手
- [Model Context Protocol](https://modelcontextprotocol.io/) - AI 代理通信標準
- [Claude](https://anthropic.com/) - AI 助手開發支援

## 📞 聯絡資訊

- **GitHub**: [GsirGinRay](https://github.com/GsirGinRay)
- **專案**: [mcp-n8n-integration](https://github.com/GsirGinRay/mcp-n8n-integration)

---

⭐ 如果這個專案對你有幫助，請給個星星支持！

🤖 **v2.1 MCP 增強更新**: 自動載入 535+ n8n 節點知識，每次創建工作流都有專業 AI 助手指導！

📺 敬請期待完整的教學影片！