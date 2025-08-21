# 🧠 自學習LINE機器人設置指南

## 📋 概述

這個優化版的LINE機器人具備以下核心自學習功能：

### 🎯 自學習特性
- **模式識別** - 自動分析用戶問題類型和回應模式
- **個人化回應** - 基於歷史對話調整回應風格
- **知識累積** - 持續學習新的問答模式
- **效果追蹤** - 監控學習模式的成功率

### 📊 Supabase數據結構
- `conversation_history` - 對話歷史記錄
- `learning_patterns` - 學習到的對話模式
- `analytics_data` - 性能分析數據
- `user_preferences` - 用戶偏好設定
- `knowledge_base` - 知識庫

## 🚀 設置步驟

### 1. Supabase 設置

#### 創建項目
1. 前往 [Supabase Dashboard](https://supabase.com/dashboard)
2. 創建新項目
3. 記錄項目URL和API密鑰

#### 執行數據庫結構
```sql
-- 在 Supabase SQL Editor 中執行 supabase-schema.sql 文件
-- 這將創建所有必要的表、索引、觸發器和視圖
```

#### 配置 API 密鑰
```bash
# 在 n8n 中創建 Supabase 憑證
# 需要：
# - Project URL: https://your-project.supabase.co
# - API Key: your-service-role-key (不是 anon key)
```

### 2. n8n 工作流設置

#### 導入工作流
1. 在 n8n 中創建新工作流
2. 導入 `Line-AI-Self-Learning.json`
3. 配置所需憑證

#### 必要憑證配置
```yaml
Supabase API:
  - Project URL: https://your-project.supabase.co
  - API Key: service_role_key

OpenAI API:
  - API Key: sk-your-openai-key
  
LINE Bot API:
  - Channel Access Token: your-line-bot-token
```

### 3. LINE Bot 設置

#### Webhook URL
```
https://your-n8n-instance.com/webhook/line-ai
```

#### 權限設置
- 確保 LINE Bot 有發送訊息權限
- 設置適當的回應模式

## 🔧 自學習機制說明

### 學習觸發條件
工作流會在以下情況下觸發學習：

1. **訂位相關** - 包含「訂位」、「預約」關鍵字
2. **菜單詢問** - 包含「菜單」、「餐點」、「推薦」
3. **外送需求** - 包含「外送」、「送餐」、「配送」
4. **營業時間** - 包含「營業」、「時間」、「開店」

### 信心度計算
```javascript
// 不同類型問題的基礎信心度
const baseConfidence = {
  reservation: 0.8,      // 訂位問題
  menu_inquiry: 0.9,     // 菜單詢問
  delivery: 0.85,        // 外送問題
  hours_inquiry: 0.75    // 營業時間
};
```

### 學習模式應用
系統會：
1. **收集歷史對話** - 獲取當日對話記錄
2. **提取學習模式** - 載入高信心度的學習模式
3. **構建個人化提示** - 結合用戶歷史和學習模式
4. **生成智能回應** - AI基於增強上下文回應
5. **分析新模式** - 從新對話中提取學習點
6. **持續優化** - 更新學習模式和信心度

## 📈 監控和分析

### 實時監控指標
```sql
-- 查看學習模式效果
SELECT * FROM learning_effectiveness;

-- 查看用戶互動統計
SELECT * FROM user_interaction_stats;

-- 查看最新學習模式
SELECT pattern_type, pattern_description, confidence_score
FROM learning_patterns 
ORDER BY created_at DESC 
LIMIT 10;
```

### 性能分析
```sql
-- 平均回應時間
SELECT AVG(response_time) as avg_response_time_ms
FROM analytics_data 
WHERE created_at > NOW() - INTERVAL '24 hours';

-- 每日對話量
SELECT DATE(created_at) as date, COUNT(*) as daily_conversations
FROM conversation_history 
GROUP BY DATE(created_at) 
ORDER BY date DESC;
```

## 🛠️ 測試指南

### 基本功能測試
1. **發送測試訊息**
   ```
   你好 → 應該收到友善回應
   營業時間 → 應該回覆營業時間資訊
   我想訂位 → 應該開始訂位流程
   ```

2. **檢查數據記錄**
   ```sql
   SELECT * FROM conversation_history ORDER BY created_at DESC LIMIT 5;
   ```

3. **驗證學習模式**
   ```sql
   SELECT * FROM learning_patterns ORDER BY created_at DESC LIMIT 5;
   ```

### 自學習功能測試
1. **重複相似問題** - 多次詢問相同類型問題
2. **檢查模式累積** - 觀察學習模式表的增長
3. **驗證個人化** - 確認回應開始個人化

### 性能測試
1. **併發測試** - 多用戶同時對話
2. **響應時間** - 監控分析數據表
3. **記憶持續性** - 測試對話上下文記憶

## 🚨 故障排除

### 常見問題

**Q: Supabase連接失敗**
```bash
# 檢查憑證配置
# 確保使用 service_role key 而非 anon key
# 驗證項目URL格式正確
```

**Q: 學習模式未保存**
```sql
-- 檢查觸發條件
SELECT shouldLearn FROM your_workflow_logs;

-- 檢查模式分析結果  
SELECT patterns FROM your_analysis_logs;
```

**Q: 回應不夠個人化**
```sql
-- 檢查歷史數據
SELECT COUNT(*) FROM conversation_history WHERE user_id = 'test_user';

-- 檢查學習模式質量
SELECT * FROM learning_patterns WHERE confidence_score > 0.7;
```

## 📚 進階配置

### 自定義學習規則
在「分析學習模式」節點中修改規則：

```javascript
// 添加新的學習模式
if (userMessage.includes('自定義關鍵字')) {
  patterns.push({
    category: 'restaurant',
    pattern_type: 'custom_type',
    pattern_description: '自定義描述',
    confidence_score: 0.8
  });
}
```

### 調整信心度閾值
在「獲取學習模式」節點中修改：

```sql
-- 提高質量門檻
WHERE confidence_score > 0.8  -- 從 0.7 調整到 0.8
```

### 擴展分析維度
在「保存分析數據」節點中添加更多分析：

```javascript
{
  sentiment_analysis: analyzeSentiment(userMessage),
  complexity_score: calculateComplexity(userMessage),
  topic_category: detectTopic(userMessage)
}
```

## 🎯 優化建議

1. **定期清理數據** - 設置數據保留政策
2. **監控性能** - 關注回應時間和準確性
3. **調整參數** - 根據實際效果調整信心度閾值
4. **擴展知識庫** - 定期更新基礎知識數據
5. **A/B測試** - 比較不同學習策略的效果

---

🤖 **自學習機器人v1.0** - 持續進化的智能助手！