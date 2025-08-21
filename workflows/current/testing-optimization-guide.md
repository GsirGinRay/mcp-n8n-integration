# 測試和優化指南 - 法說會自動化系統

## 🧪 測試階段

### 1. 單元測試 - 個別節點測試

#### 測試 Puppeteer 抓取
```javascript
// 在 n8n Code 節點中運行此測試
const testScraping = async () => {
  const puppeteer = require('puppeteer');
  
  console.log('開始測試 MOPS 網站抓取...');
  
  const browser = await puppeteer.launch({ headless: false }); // 設為 false 以觀察過程
  const page = await browser.newPage();
  
  try {
    await page.goto('https://mops.twse.com.tw/mops/web/t100sb02_1.html', {
      waitUntil: 'networkidle2',
      timeout: 30000
    });
    
    console.log('頁面載入成功');
    
    // 檢查是否有表格
    const tableExists = await page.$('table') !== null;
    console.log('表格存在:', tableExists);
    
    // 測試資料提取
    const sampleData = await page.evaluate(() => {
      const firstRow = document.querySelector('table tr:nth-child(2)');
      if (!firstRow) return null;
      
      const cells = firstRow.querySelectorAll('td');
      return {
        cellCount: cells.length,
        firstCell: cells[0]?.textContent?.trim(),
        secondCell: cells[1]?.textContent?.trim()
      };
    });
    
    console.log('範例資料:', sampleData);
    
    await browser.close();
    return { success: true, data: sampleData };
    
  } catch (error) {
    await browser.close();
    console.error('測試失敗:', error);
    return { success: false, error: error.message };
  }
};

return [{ json: await testScraping() }];
```

#### 測試 Supabase 連接
```sql
-- 在 Supabase SQL Editor 中運行
SELECT 
  'Supabase 連接正常' as status,
  NOW() as current_time,
  COUNT(*) as existing_records
FROM investor_conferences;

-- 測試函數是否正常
SELECT get_conference_stats();

-- 測試插入功能
SELECT upsert_investor_conference(
  '2330', '台積電', '2024-01-15', 'Q4', 2023,
  'https://example.com/test.pdf', 'test.pdf'
);
```

### 2. 整合測試 - 完整工作流程

#### 手動執行測試
1. 在 n8n 中手動觸發工作流程
2. 檢查每個節點的執行結果
3. 驗證 Supabase 中的資料

```javascript
// 測試工作流程狀態監控節點
const workflowStatus = {
  execution_id: $execution.id,
  workflow_name: $workflow.name,
  start_time: new Date().toISOString(),
  nodes_executed: Object.keys($input.all()).length,
  success_count: $input.all().filter(item => !item.json.error).length,
  error_count: $input.all().filter(item => item.json.error).length
};

console.log('工作流程執行狀態:', workflowStatus);

return [{ json: workflowStatus }];
```

### 3. 壓力測試

#### 模擬大量資料處理
```javascript
// 在 Code 節點中生成測試資料
const generateTestData = (count) => {
  const testData = [];
  const companies = ['台積電', '鴻海', '聯發科', '台達電', '中鋼'];
  
  for (let i = 0; i < count; i++) {
    testData.push({
      json: {
        stock_code: `${2330 + i}`,
        company_name: companies[i % companies.length],
        conference_date: `2024-01-${(i % 28) + 1}`,
        quarter: `Q${(i % 4) + 1}`,
        year: 2024,
        presentation_url: `https://example.com/test_${i}.pdf`,
        file_name: `test_${i}.pdf`,
        status: 'pending',
        scraped_at: new Date().toISOString()
      }
    });
  }
  
  return testData;
};

// 生成 100 筆測試資料
return generateTestData(100);
```

## 📊 監控和日誌

### 1. 執行監控儀表板

在 Supabase 中創建監控視圖：
```sql
-- 創建執行日誌表
CREATE TABLE workflow_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    execution_id VARCHAR(100),
    workflow_name VARCHAR(100),
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20), -- success, error, timeout
    records_processed INTEGER,
    records_inserted INTEGER,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 監控視圖
CREATE VIEW monitoring_dashboard AS
SELECT 
    DATE(created_at) as date,
    COUNT(*) as total_executions,
    COUNT(CASE WHEN status = 'success' THEN 1 END) as successful_executions,
    COUNT(CASE WHEN status = 'error' THEN 1 END) as failed_executions,
    AVG(records_processed) as avg_records_processed,
    AVG(EXTRACT(EPOCH FROM (end_time - start_time))) as avg_duration_seconds
FROM workflow_logs
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

### 2. 錯誤追蹤和告警

```javascript
// 錯誤監控節點
const monitorErrors = () => {
  const errors = $input.all().filter(item => item.json.error);
  
  if (errors.length > 0) {
    // 記錄錯誤到資料庫
    const errorLog = {
      execution_id: $execution.id,
      workflow_name: $workflow.name,
      error_count: errors.length,
      error_details: errors.map(e => ({
        message: e.json.error.message,
        stack: e.json.error.stack,
        timestamp: new Date().toISOString()
      })),
      created_at: new Date().toISOString()
    };
    
    // 如果錯誤率超過閾值，發送告警
    const errorRate = errors.length / $input.all().length;
    if (errorRate > 0.5) { // 50% 錯誤率
      return [{
        json: {
          alert: true,
          message: `⚠️ 高錯誤率警告: ${(errorRate * 100).toFixed(1)}%`,
          details: errorLog
        }
      }];
    }
  }
  
  return [{ json: { alert: false, message: '執行正常' } }];
};

return monitorErrors();
```

## ⚡ 效能優化

### 1. 爬取效能優化

```javascript
// 優化的 Puppeteer 配置
const optimizedBrowser = await puppeteer.launch({
  headless: true,
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage',
    '--disable-accelerated-2d-canvas',
    '--no-first-run',
    '--no-zygote',
    '--disable-gpu'
  ]
});

const page = await optimizedBrowser.newPage();

// 禁用不必要的資源
await page.setRequestInterception(true);
page.on('request', (req) => {
  const resourceType = req.resourceType();
  if (['image', 'stylesheet', 'font'].includes(resourceType)) {
    req.abort();
  } else {
    req.continue();
  }
});

// 設定較短的超時時間
await page.setDefaultTimeout(15000);
```

### 2. 資料庫優化

```sql
-- 優化查詢的索引
CREATE INDEX CONCURRENTLY idx_investor_conferences_compound 
ON investor_conferences (stock_code, conference_date DESC, status);

-- 分區表 (如果資料量很大)
CREATE TABLE investor_conferences_2024 
PARTITION OF investor_conferences 
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- 清理舊資料的排程
SELECT cron.schedule('cleanup-old-conferences', '0 2 * * 0', 'SELECT cleanup_old_conferences();');
```

### 3. 工作流程優化

```javascript
// 批量處理優化
const batchSize = 50;
const items = $input.all();
const batches = [];

for (let i = 0; i < items.length; i += batchSize) {
  batches.push(items.slice(i, i + batchSize));
}

const results = [];
for (const batch of batches) {
  // 處理每個批次
  const batchResults = await processBatch(batch);
  results.push(...batchResults);
  
  // 批次間休息
  await new Promise(resolve => setTimeout(resolve, 2000));
}

return results;
```

## 🔍 故障排除

### 常見問題和解決方案

#### 1. 網站無法訪問
```javascript
// 網站健康檢查
const checkWebsiteHealth = async () => {
  const puppeteer = require('puppeteer');
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  try {
    const response = await page.goto('https://mops.twse.com.tw/', {
      waitUntil: 'networkidle2',
      timeout: 10000
    });
    
    await browser.close();
    
    return {
      status: response.status(),
      ok: response.ok(),
      url: response.url(),
      message: response.ok() ? '網站正常' : '網站異常'
    };
  } catch (error) {
    await browser.close();
    return {
      status: 0,
      ok: false,
      error: error.message,
      message: '無法訪問網站'
    };
  }
};

return [{ json: await checkWebsiteHealth() }];
```

#### 2. 資料格式異常
```javascript
// 資料驗證和修復
const validateAndFixData = (data) => {
  const fixed = { ...data };
  
  // 修復股票代碼
  if (fixed.stock_code) {
    fixed.stock_code = fixed.stock_code.replace(/[^\d]/g, '').substring(0, 10);
  }
  
  // 修復日期格式
  if (fixed.conference_date) {
    const dateMatch = fixed.conference_date.match(/(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})/);
    if (dateMatch) {
      const [, year, month, day] = dateMatch;
      fixed.conference_date = `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
      fixed.year = parseInt(year);
    }
  }
  
  // 驗證必要欄位
  const required = ['stock_code', 'company_name', 'conference_date'];
  const isValid = required.every(field => fixed[field] && fixed[field].trim() !== '');
  
  return { data: fixed, isValid };
};

const processedItems = $input.all().map(item => {
  const result = validateAndFixData(item.json);
  return result.isValid ? { json: result.data } : null;
}).filter(item => item !== null);

return processedItems;
```

#### 3. Supabase 連接問題
```javascript
// Supabase 連接測試
const testSupabaseConnection = async () => {
  try {
    // 測試簡單查詢
    const { createClient } = require('@supabase/supabase-js');
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_KEY
    );
    
    const { data, error } = await supabase
      .from('investor_conferences')
      .select('count', { count: 'exact', head: true });
    
    if (error) throw error;
    
    return {
      status: 'connected',
      record_count: data,
      message: 'Supabase 連接正常'
    };
  } catch (error) {
    return {
      status: 'error',
      error: error.message,
      message: 'Supabase 連接失敗'
    };
  }
};

return [{ json: await testSupabaseConnection() }];
```

## 📈 效能指標

### 建議的 KPI 監控
- 執行成功率 (目標: >95%)
- 平均執行時間 (目標: <5分鐘)
- 新資料發現率 (每日新增記錄數)
- 錯誤率 (目標: <5%)
- 資源使用率 (CPU, 記憶體)

### 告警設定
```javascript
// KPI 監控節點
const checkKPIs = async () => {
  const alerts = [];
  
  // 檢查執行時間
  const duration = (Date.now() - $execution.startedAt) / 1000;
  if (duration > 300) { // 5分鐘
    alerts.push(`⚠️ 執行時間過長: ${duration}秒`);
  }
  
  // 檢查錯誤率
  const totalItems = $input.all().length;
  const errorItems = $input.all().filter(item => item.json.error).length;
  const errorRate = errorItems / totalItems;
  
  if (errorRate > 0.05) { // 5%
    alerts.push(`⚠️ 錯誤率過高: ${(errorRate * 100).toFixed(1)}%`);
  }
  
  return alerts.length > 0 ? 
    [{ json: { alerts, status: 'warning' } }] : 
    [{ json: { message: '所有指標正常', status: 'ok' } }];
};

return await checkKPIs();
```

這個完整的解決方案現在可以幫你自動化法說會簡報的抓取和管理！