# n8n 法說會簡報自動化實作指南

## 📋 前置準備

### 1. 安裝必要的 n8n 節點
```bash
# 安裝 Supabase 節點
npm install n8n-nodes-supabase

# 安裝 Puppeteer (用於處理動態網站)
npm install puppeteer

# 安裝額外的解析工具
npm install cheerio
```

### 2. 環境變數設定
```bash
# 複製設定檔案
cp workflows/current/supabase-config.env .env

# 編輯環境變數
nano .env
```

## 🔧 節點配置詳解

### 1. Cron 觸發器節點
```json
{
  "parameters": {
    "rule": {
      "interval": [
        {
          "field": "hours", 
          "hoursInterval": 6
        }
      ]
    },
    "options": {
      "timezone": "Asia/Taipei"
    }
  },
  "name": "定時觸發器",
  "type": "n8n-nodes-base.cron"
}
```

### 2. Puppeteer 抓取節點 (推薦方案)
由於 MOPS 網站有反爬蟲機制，使用 Puppeteer 更穩定：

```javascript
// Code 節點 - Puppeteer 抓取
const puppeteer = require('puppeteer');

const browser = await puppeteer.launch({
  headless: true,
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage'
  ]
});

const page = await browser.newPage();

// 設定 User-Agent 和其他 headers
await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
await page.setExtraHTTPHeaders({
  'Accept-Language': 'zh-TW,zh;q=0.9,en;q=0.8'
});

try {
  // 前往 MOPS 網站
  await page.goto('https://mops.twse.com.tw/mops/web/t100sb02_1.html', {
    waitUntil: 'networkidle2',
    timeout: 30000
  });

  // 等待表格載入
  await page.waitForSelector('table', { timeout: 10000 });

  // 提取法說會資料
  const conferences = await page.evaluate(() => {
    const rows = Array.from(document.querySelectorAll('table tr'));
    const data = [];

    rows.forEach((row, index) => {
      if (index === 0) return; // 跳過標題行

      const cells = row.querySelectorAll('td');
      if (cells.length >= 5) {
        const stockCode = cells[0]?.textContent?.trim();
        const companyName = cells[1]?.textContent?.trim();
        const conferenceDate = cells[2]?.textContent?.trim();
        const quarter = cells[3]?.textContent?.trim();
        
        // 提取下載連結
        const linkElement = cells[4]?.querySelector('a');
        const presentationUrl = linkElement?.href;
        
        if (stockCode && companyName && conferenceDate) {
          data.push({
            stock_code: stockCode,
            company_name: companyName,
            conference_date: conferenceDate,
            quarter: quarter,
            year: new Date(conferenceDate).getFullYear(),
            presentation_url: presentationUrl,
            file_name: presentationUrl ? presentationUrl.split('/').pop() : null,
            conference_type: '法說會',
            status: 'pending',
            scraped_at: new Date().toISOString()
          });
        }
      }
    });

    return data;
  });

  await browser.close();
  
  return conferences.map(item => ({ json: item }));

} catch (error) {
  await browser.close();
  throw new Error(`抓取失敗: ${error.message}`);
}
```

### 3. 資料處理和清理節點
```javascript
// Code 節點 - 資料清理
const items = [];

for (const item of $input.all()) {
  const data = item.json;
  
  // 資料清理和驗證
  if (data.stock_code && data.company_name && data.conference_date) {
    // 正規化日期格式
    const dateMatch = data.conference_date.match(/(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})/);
    if (dateMatch) {
      const [, year, month, day] = dateMatch;
      data.conference_date = `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
      data.year = parseInt(year);
    }
    
    // 清理股票代碼
    data.stock_code = data.stock_code.replace(/[^\d]/g, '');
    
    // 處理簡報 URL
    if (data.presentation_url && !data.presentation_url.startsWith('http')) {
      data.presentation_url = 'https://mops.twse.com.tw' + data.presentation_url;
    }
    
    // 生成檔案名稱
    if (!data.file_name && data.presentation_url) {
      data.file_name = `${data.stock_code}_${data.quarter}_${data.year}.pdf`;
    }
    
    items.push({ json: data });
  }
}

return items;
```

### 4. Supabase 重複檢查節點
```json
{
  "parameters": {
    "authentication": "serviceAccount",
    "operation": "select",
    "table": "investor_conferences",
    "filterType": "manual",
    "matchType": "allFilters",
    "filters": {
      "conditions": [
        {
          "keyName": "stock_code",
          "condition": "equals",
          "keyValue": "={{ $json.stock_code }}"
        },
        {
          "keyName": "conference_date", 
          "condition": "equals",
          "keyValue": "={{ $json.conference_date }}"
        },
        {
          "keyName": "quarter",
          "condition": "equals", 
          "keyValue": "={{ $json.quarter }}"
        }
      ]
    }
  },
  "name": "檢查重複資料",
  "type": "n8n-nodes-base.supabase"
}
```

### 5. 條件分支節點
```json
{
  "parameters": {
    "conditions": {
      "options": {
        "caseSensitive": true,
        "leftValue": "",
        "typeValidation": "strict"
      },
      "conditions": [
        {
          "leftValue": "={{ $('檢查重複資料').itemMatching(0).$json.length || 0 }}",
          "rightValue": 0,
          "operator": {
            "type": "number",
            "operation": "equals"
          }
        }
      ],
      "combinator": "and"
    }
  },
  "name": "篩選新記錄",
  "type": "n8n-nodes-base.if"
}
```

### 6. Supabase 插入節點
```json
{
  "parameters": {
    "authentication": "serviceAccount", 
    "operation": "insert",
    "table": "investor_conferences",
    "columns": {
      "mappingMode": "defineBelow",
      "value": {
        "stock_code": "={{ $json.stock_code }}",
        "company_name": "={{ $json.company_name }}",
        "conference_date": "={{ $json.conference_date }}",
        "quarter": "={{ $json.quarter }}",
        "year": "={{ $json.year }}",
        "presentation_url": "={{ $json.presentation_url }}",
        "file_name": "={{ $json.file_name }}",
        "conference_type": "={{ $json.conference_type }}",
        "status": "={{ $json.status }}",
        "scraped_at": "={{ $json.scraped_at }}"
      }
    },
    "options": {
      "upsert": true
    }
  },
  "name": "存入 Supabase",
  "type": "n8n-nodes-base.supabase"
}
```

## 🚨 錯誤處理

### 錯誤捕獲節點
```javascript
// Code 節點 - 錯誤處理
const errors = [];

for (const item of $input.all()) {
  if (item.json.error) {
    errors.push({
      json: {
        timestamp: new Date().toISOString(),
        error_type: 'scraping_error',
        error_message: item.json.error.message,
        error_stack: item.json.error.stack,
        node_name: '{{ $workflow.name }}',
        execution_id: '{{ $execution.id }}'
      }
    });
  }
}

return errors.length > 0 ? errors : [{ json: { message: '執行成功，無錯誤' } }];
```

## 📊 監控和通知

### Slack 通知節點
```json
{
  "parameters": {
    "authentication": "webhook",
    "webhookUrl": "={{ $env.SLACK_WEBHOOK_URL }}",
    "channel": "#投資人會議",
    "username": "n8n-bot",
    "text": "📈 成功處理 {{ $('存入 Supabase').itemMatching(0).$json.length || 0 }} 筆法說會資料\\n時間: {{ new Date().toLocaleString('zh-TW') }}",
    "otherOptions": {
      "icon_emoji": ":chart_with_upwards_trend:"
    }
  },
  "name": "成功通知",
  "type": "n8n-nodes-base.slack"
}
```

## ⚡ 效能優化建議

1. **批量處理**: 設定適當的批次大小 (建議 50-100 筆)
2. **請求間隔**: 在 HTTP 請求間加入延遲 (建議 2-5 秒)
3. **錯誤重試**: 實作指數退避重試機制
4. **資料去重**: 在資料庫層面實作唯一約束
5. **監控告警**: 設定執行失敗的即時通知

## 🔒 安全考量

1. **API 金鑰管理**: 使用環境變數存儲敏感資訊
2. **存取權限**: 設定適當的 Supabase RLS 政策
3. **請求頻率**: 遵守網站的爬蟲規範
4. **資料備份**: 定期備份重要資料
5. **日誌記錄**: 記錄所有操作以便追蹤