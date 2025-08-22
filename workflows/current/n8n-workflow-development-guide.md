# n8n 工作流自動化開發指南

## 🎯 目標
確保每次執行 `/n8n-mcp` 後開發的工作流都是真正可用的 n8n JSON 檔案。

## 🔄 自動化開發流程

### 步驟 1: 研究階段
```
1. 檢查 MCP 現有案例 → 分析相似節點配置
2. 查詢 n8n 官方文檔 → 確認最新 API 參數  
3. 驗證 JSON 格式標準 → 確保結構完整
```

### 步驟 2: 開發階段
```
1. 使用真實 n8n 節點類型
2. 設置正確的 typeVersion
3. 建立完整的連接結構
4. 配置必要的 credentials
```

### 步驟 3: 品質保證
```
1. JSON 語法驗證
2. 節點連接檢查
3. 參數完整性確認
4. 可導入性測試
```

## 📋 標準 n8n 工作流結構

### 必要字段檢查清單
- [ ] `name` - 工作流名稱
- [ ] `active` - 啟用狀態（預設 false）
- [ ] `nodes` - 節點陣列
- [ ] `connections` - 節點連接配置
- [ ] `settings` - 工作流設定
- [ ] `staticData` - 靜態資料
- [ ] `tags` - 標籤陣列
- [ ] `triggerCount` - 觸發器數量
- [ ] `updatedAt` - 更新時間
- [ ] `versionId` - 版本號

### 節點配置檢查清單
- [ ] `id` - 唯一識別符
- [ ] `name` - 節點顯示名稱
- [ ] `type` - 正確的節點類型（如 n8n-nodes-base.webhook）
- [ ] `typeVersion` - 節點版本號
- [ ] `position` - [x, y] 座標陣列
- [ ] `parameters` - 節點參數物件

## 🛠️ 常用 n8n 節點類型參考

### 觸發器節點
- `n8n-nodes-base.webhook` - HTTP Webhook
- `n8n-nodes-base.manualTrigger` - 手動觸發
- `n8n-nodes-base.cronTrigger` - 定時觸發
- `n8n-nodes-base.emailTrigger` - 郵件觸發

### 應用節點
- `n8n-nodes-base.httpRequest` - HTTP 請求
- `n8n-nodes-base.googleCalendar` - Google 日曆
- `n8n-nodes-base.googleSheets` - Google 試算表
- `n8n-nodes-base.slack` - Slack
- `n8n-nodes-base.telegram` - Telegram
- `n8n-nodes-base.line` - LINE

### 核心節點
- `n8n-nodes-base.function` - JavaScript 函數
- `n8n-nodes-base.code` - 程式碼執行
- `n8n-nodes-base.if` - 條件判斷
- `n8n-nodes-base.merge` - 資料合併
- `n8n-nodes-base.set` - 設定變數

### 資料庫節點
- `n8n-nodes-base.mysql` - MySQL
- `n8n-nodes-base.postgres` - PostgreSQL
- `n8n-nodes-base.supabase` - Supabase
- `n8n-nodes-base.mongodb` - MongoDB

## 🔍 品質檢查工具

### JSON 語法驗證
```javascript
try {
  const workflow = JSON.parse(workflowJson);
  console.log('✅ JSON 語法正確');
} catch (error) {
  console.error('❌ JSON 語法錯誤:', error.message);
}
```

### 必要字段檢查
```javascript
const requiredFields = ['name', 'nodes', 'connections', 'settings'];
const missingFields = requiredFields.filter(field => !workflow[field]);
if (missingFields.length === 0) {
  console.log('✅ 必要字段完整');
} else {
  console.error('❌ 缺少字段:', missingFields);
}
```

### 節點連接驗證
```javascript
const nodeIds = workflow.nodes.map(node => node.id);
const connectionErrors = [];

Object.keys(workflow.connections).forEach(sourceNode => {
  if (!nodeIds.includes(sourceNode)) {
    connectionErrors.push(`未找到來源節點: ${sourceNode}`);
  }
});

if (connectionErrors.length === 0) {
  console.log('✅ 節點連接正確');
} else {
  console.error('❌ 連接錯誤:', connectionErrors);
}
```

## 📚 參考資源

### n8n 官方文檔
- [Node Types](https://docs.n8n.io/integrations/)
- [Workflow Structure](https://docs.n8n.io/workflows/)
- [Node Development](https://docs.n8n.io/development/)

### MCP 最佳實踐
- 參考 `workflows/current/` 中的成功案例
- 學習現有工作流的節點配置模式
- 複用經過驗證的連接結構

## ⚠️ 常見錯誤避免

### 錯誤的節點類型
```json
// ❌ 錯誤
"type": "googleSpeechToText"

// ✅ 正確
"type": "n8n-nodes-base.googleSpeechToText"
```

### 缺少必要字段
```json
// ❌ 錯誤 - 缺少 typeVersion
{
  "id": "node1",
  "name": "HTTP Request",
  "type": "n8n-nodes-base.httpRequest"
}

// ✅ 正確 - 包含所有必要字段
{
  "id": "node1",
  "name": "HTTP Request", 
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.1,
  "position": [240, 300],
  "parameters": {}
}
```

### 錯誤的連接格式
```json
// ❌ 錯誤
"connections": {
  "node1": "node2"
}

// ✅ 正確
"connections": {
  "node1": {
    "main": [
      [
        {
          "node": "node2",
          "type": "main",
          "index": 0
        }
      ]
    ]
  }
}
```

## 🎯 成功案例模板

以下是一個標準的 n8n 工作流 JSON 模板：

```json
{
  "name": "範例工作流",
  "active": false,
  "nodes": [
    {
      "parameters": {
        "path": "example",
        "httpMethod": "POST"
      },
      "id": "webhook-node",
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 2.1,
      "position": [240, 300],
      "webhookId": "example-webhook"
    },
    {
      "parameters": {
        "functionCode": "return $input.all();"
      },
      "id": "function-node",
      "name": "Function",
      "type": "n8n-nodes-base.function",
      "typeVersion": 1,
      "position": [440, 300]
    }
  ],
  "connections": {
    "Webhook": {
      "main": [
        [
          {
            "node": "Function",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "settings": {},
  "staticData": {},
  "tags": ["範例", "模板"],
  "triggerCount": 1,
  "updatedAt": "2025-01-22T00:00:00.000Z",
  "versionId": "1.0"
}
```