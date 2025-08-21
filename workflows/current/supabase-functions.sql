-- Supabase 輔助函數 - 法說會簡報管理

-- 1. 取得最新的法說會簡報
CREATE OR REPLACE FUNCTION get_latest_investor_conferences(limit_count INT DEFAULT 20)
RETURNS TABLE (
    id UUID,
    stock_code VARCHAR(10),
    company_name VARCHAR(100),
    conference_date DATE,
    quarter VARCHAR(10),
    presentation_url TEXT,
    file_name VARCHAR(255),
    scraped_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE sql
AS $$
    SELECT 
        id, stock_code, company_name, conference_date, 
        quarter, presentation_url, file_name, scraped_at
    FROM investor_conferences 
    WHERE status != 'error'
    ORDER BY conference_date DESC, scraped_at DESC
    LIMIT limit_count;
$$;

-- 2. 依股票代碼搜尋法說會簡報
CREATE OR REPLACE FUNCTION search_by_stock_code(search_code VARCHAR(10))
RETURNS TABLE (
    id UUID,
    stock_code VARCHAR(10),
    company_name VARCHAR(100),
    conference_date DATE,
    quarter VARCHAR(10),
    presentation_url TEXT,
    status VARCHAR(20)
) 
LANGUAGE sql
AS $$
    SELECT 
        id, stock_code, company_name, conference_date, 
        quarter, presentation_url, status
    FROM investor_conferences 
    WHERE stock_code = search_code
    ORDER BY conference_date DESC;
$$;

-- 3. 取得統計資訊
CREATE OR REPLACE FUNCTION get_conference_stats()
RETURNS TABLE (
    total_conferences BIGINT,
    total_companies BIGINT,
    latest_update TIMESTAMP WITH TIME ZONE,
    status_breakdown JSONB
) 
LANGUAGE sql
AS $$
    SELECT 
        COUNT(*) as total_conferences,
        COUNT(DISTINCT stock_code) as total_companies,
        MAX(scraped_at) as latest_update,
        jsonb_object_agg(status, status_count) as status_breakdown
    FROM (
        SELECT status, COUNT(*) as status_count
        FROM investor_conferences 
        GROUP BY status
    ) status_counts,
    investor_conferences;
$$;

-- 4. 清理舊資料 (保留最近一年)
CREATE OR REPLACE FUNCTION cleanup_old_conferences()
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    deleted_count INT;
BEGIN
    DELETE FROM investor_conferences 
    WHERE conference_date < CURRENT_DATE - INTERVAL '1 year'
    AND status IN ('error', 'pending');
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$;

-- 5. 批量更新狀態
CREATE OR REPLACE FUNCTION update_conference_status(
    conference_ids UUID[],
    new_status VARCHAR(20)
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    updated_count INT;
BEGIN
    UPDATE investor_conferences 
    SET status = new_status, updated_at = NOW()
    WHERE id = ANY(conference_ids);
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    RETURN updated_count;
END;
$$;

-- 6. 建立 API 視圖 (供外部查詢使用)
CREATE OR REPLACE VIEW public_conferences AS
SELECT 
    stock_code,
    company_name,
    conference_date,
    quarter,
    year,
    conference_type,
    CASE 
        WHEN presentation_url IS NOT NULL THEN true 
        ELSE false 
    END as has_presentation,
    scraped_at::DATE as data_date
FROM investor_conferences 
WHERE status = 'downloaded' OR status = 'processed'
ORDER BY conference_date DESC;

-- 7. 觸發器：自動更新 updated_at
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER set_timestamp
    BEFORE UPDATE ON investor_conferences
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- 8. 防重複插入的函數
CREATE OR REPLACE FUNCTION upsert_investor_conference(
    p_stock_code VARCHAR(10),
    p_company_name VARCHAR(100),
    p_conference_date DATE,
    p_quarter VARCHAR(10),
    p_year INTEGER,
    p_presentation_url TEXT,
    p_file_name VARCHAR(255)
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    conference_id UUID;
BEGIN
    -- 嘗試插入，如果重複則更新
    INSERT INTO investor_conferences (
        stock_code, company_name, conference_date, quarter, year,
        presentation_url, file_name, status, scraped_at
    ) VALUES (
        p_stock_code, p_company_name, p_conference_date, p_quarter, p_year,
        p_presentation_url, p_file_name, 'pending', NOW()
    ) 
    ON CONFLICT (stock_code, conference_date, quarter)
    DO UPDATE SET
        presentation_url = EXCLUDED.presentation_url,
        file_name = EXCLUDED.file_name,
        updated_at = NOW()
    RETURNING id INTO conference_id;
    
    RETURN conference_id;
END;
$$;