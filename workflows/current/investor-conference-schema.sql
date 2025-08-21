-- 法說會簡報資料表
CREATE TABLE investor_conferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    stock_code VARCHAR(10) NOT NULL,                 -- 股票代碼
    company_name VARCHAR(100) NOT NULL,              -- 公司名稱
    conference_date DATE NOT NULL,                   -- 法說會日期
    year INTEGER NOT NULL,                           -- 年度
    quarter VARCHAR(10),                             -- 財季 (Q1, Q2, Q3, Q4, 年報等)
    conference_type VARCHAR(50) DEFAULT '法說會',     -- 會議類型
    
    -- 檔案資訊
    presentation_url TEXT,                           -- 簡報檔案 URL
    file_name VARCHAR(255),                          -- 檔案名稱
    file_size INTEGER,                               -- 檔案大小 (bytes)
    file_type VARCHAR(10) DEFAULT 'PDF',             -- 檔案類型
    local_path TEXT,                                 -- 本地存儲路徑 (可選)
    
    -- 系統資訊
    scraped_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- 抓取時間
    published_at TIMESTAMP WITH TIME ZONE,           -- 發布時間
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- 更新時間
    status VARCHAR(20) DEFAULT 'pending',            -- 狀態: pending, downloaded, processed, error
    
    -- 額外資訊
    notes TEXT,                                      -- 備註
    metadata JSONB,                                  -- 額外的中繼資料
    
    UNIQUE(stock_code, conference_date, quarter)     -- 防重複約束
);

-- 創建索引
CREATE INDEX idx_investor_conferences_stock_code ON investor_conferences(stock_code);
CREATE INDEX idx_investor_conferences_date ON investor_conferences(conference_date DESC);
CREATE INDEX idx_investor_conferences_status ON investor_conferences(status);
CREATE INDEX idx_investor_conferences_year_quarter ON investor_conferences(year, quarter);

-- 創建 RLS 政策 (可選，根據需求調整)
ALTER TABLE investor_conferences ENABLE ROW LEVEL SECURITY;

-- 允許讀取所有資料
CREATE POLICY "允許讀取法說會資料" ON investor_conferences
    FOR SELECT USING (true);

-- 允許插入新資料
CREATE POLICY "允許插入法說會資料" ON investor_conferences
    FOR INSERT WITH CHECK (true);

-- 允許更新資料
CREATE POLICY "允許更新法說會資料" ON investor_conferences
    FOR UPDATE USING (true);