-- 📁 Google Drive 到 Supabase 同步系統數據庫結構
-- 創建日期: 2025-08-18

-- ===================================
-- 1. 文件同步記錄表
-- ===================================
CREATE TABLE IF NOT EXISTS file_sync_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Google Drive 文件資訊
    file_id VARCHAR(255) NOT NULL UNIQUE,
    file_name VARCHAR(500) NOT NULL,
    file_type VARCHAR(100), -- csv, xlsx, json
    file_size_bytes BIGINT,
    file_modified_time TIMESTAMP WITH TIME ZONE,
    file_drive_path TEXT,
    
    -- 同步狀態
    sync_status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, processing, completed, failed
    last_sync_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    next_sync_time TIMESTAMP WITH TIME ZONE,
    sync_attempts INTEGER DEFAULT 0,
    max_sync_attempts INTEGER DEFAULT 3,
    
    -- 目標表資訊
    target_table_name VARCHAR(255),
    target_schema VARCHAR(100) DEFAULT 'public',
    records_imported INTEGER DEFAULT 0,
    import_batch_id VARCHAR(100),
    
    -- 處理結果
    processing_time_ms INTEGER,
    error_message TEXT,
    warning_messages TEXT[],
    
    -- 表結構資訊
    column_definitions JSONB, -- 存儲列定義
    data_sample JSONB, -- 存儲數據樣本
    
    -- 同步配置
    sync_mode VARCHAR(50) DEFAULT 'full_replace', -- full_replace, incremental, append_only
    auto_sync_enabled BOOLEAN DEFAULT true,
    sync_schedule VARCHAR(100), -- cron 表達式
    
    -- 元數據
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by VARCHAR(100) DEFAULT 'system',
    
    -- 數據品質檢查
    data_quality_score DECIMAL(3,2), -- 0-1 分數
    validation_errors JSONB,
    duplicate_count INTEGER DEFAULT 0,
    null_count INTEGER DEFAULT 0
);

-- 文件同步記錄索引
CREATE INDEX IF NOT EXISTS idx_file_sync_file_id ON file_sync_log(file_id);
CREATE INDEX IF NOT EXISTS idx_file_sync_status ON file_sync_log(sync_status);
CREATE INDEX IF NOT EXISTS idx_file_sync_last_sync ON file_sync_log(last_sync_time);
CREATE INDEX IF NOT EXISTS idx_file_sync_table_name ON file_sync_log(target_table_name);
CREATE INDEX IF NOT EXISTS idx_file_sync_auto_enabled ON file_sync_log(auto_sync_enabled);

-- ===================================
-- 2. 數據同步配置表
-- ===================================
CREATE TABLE IF NOT EXISTS sync_configurations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- 配置名稱
    config_name VARCHAR(200) NOT NULL UNIQUE,
    description TEXT,
    
    -- Google Drive 設定
    source_folder_id VARCHAR(255) NOT NULL,
    source_folder_path TEXT,
    file_patterns TEXT[] DEFAULT ARRAY['*.csv', '*.xlsx', '*.json'], -- 支援的文件格式
    
    -- 目標設定
    target_database VARCHAR(100) DEFAULT 'supabase',
    target_schema VARCHAR(100) DEFAULT 'public',
    table_name_template VARCHAR(200) DEFAULT '{{ filename }}', -- 動態表名模板
    
    -- 同步設定
    sync_schedule VARCHAR(100) DEFAULT '*/10 * * * *', -- 每10分鐘
    sync_mode VARCHAR(50) DEFAULT 'full_replace',
    batch_size INTEGER DEFAULT 1000,
    max_file_size_mb INTEGER DEFAULT 100,
    
    -- 數據處理設定
    auto_create_tables BOOLEAN DEFAULT true,
    auto_detect_types BOOLEAN DEFAULT true,
    skip_empty_files BOOLEAN DEFAULT true,
    normalize_column_names BOOLEAN DEFAULT true,
    
    -- 通知設定
    notify_on_success BOOLEAN DEFAULT false,
    notify_on_failure BOOLEAN DEFAULT true,
    notification_webhook TEXT,
    notification_email VARCHAR(255),
    
    -- 狀態
    is_active BOOLEAN DEFAULT true,
    last_execution TIMESTAMP WITH TIME ZONE,
    next_execution TIMESTAMP WITH TIME ZONE,
    
    -- 統計
    total_executions INTEGER DEFAULT 0,
    successful_executions INTEGER DEFAULT 0,
    failed_executions INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 同步配置索引
CREATE INDEX IF NOT EXISTS idx_sync_config_active ON sync_configurations(is_active);
CREATE INDEX IF NOT EXISTS idx_sync_config_schedule ON sync_configurations(sync_schedule);
CREATE INDEX IF NOT EXISTS idx_sync_config_folder ON sync_configurations(source_folder_id);

-- ===================================
-- 3. 數據表元數據管理
-- ===================================
CREATE TABLE IF NOT EXISTS managed_tables (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- 表基本資訊
    table_name VARCHAR(255) NOT NULL,
    table_schema VARCHAR(100) DEFAULT 'public',
    display_name VARCHAR(300),
    description TEXT,
    
    -- 來源資訊
    source_type VARCHAR(100) DEFAULT 'google_drive', -- google_drive, manual, api
    source_file_id VARCHAR(255),
    source_file_name VARCHAR(500),
    source_config_id UUID REFERENCES sync_configurations(id),
    
    -- 表結構
    column_count INTEGER,
    total_records BIGINT DEFAULT 0,
    estimated_size_mb DECIMAL(10,2),
    
    -- 同步狀態
    sync_status VARCHAR(50) DEFAULT 'active', -- active, paused, archived
    last_sync_time TIMESTAMP WITH TIME ZONE,
    last_record_count BIGINT,
    sync_frequency VARCHAR(100),
    
    -- 數據品質
    data_quality_score DECIMAL(3,2),
    has_primary_key BOOLEAN DEFAULT false,
    has_indexes BOOLEAN DEFAULT false,
    constraint_violations INTEGER DEFAULT 0,
    
    -- 使用統計
    query_count INTEGER DEFAULT 0,
    last_accessed TIMESTAMP WITH TIME ZONE,
    access_frequency VARCHAR(50) DEFAULT 'unknown', -- high, medium, low, unknown
    
    -- 標籤和分類
    tags TEXT[],
    category VARCHAR(100),
    business_owner VARCHAR(100),
    technical_owner VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 管理表索引
CREATE UNIQUE INDEX IF NOT EXISTS idx_managed_tables_unique ON managed_tables(table_schema, table_name);
CREATE INDEX IF NOT EXISTS idx_managed_tables_source ON managed_tables(source_type, source_file_id);
CREATE INDEX IF NOT EXISTS idx_managed_tables_sync_status ON managed_tables(sync_status);
CREATE INDEX IF NOT EXISTS idx_managed_tables_category ON managed_tables(category);

-- ===================================
-- 4. 同步執行歷史
-- ===================================
CREATE TABLE IF NOT EXISTS sync_execution_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- 執行資訊
    execution_id VARCHAR(100) NOT NULL,
    config_id UUID REFERENCES sync_configurations(id),
    file_sync_log_id UUID REFERENCES file_sync_log(id),
    
    -- 執行狀態
    execution_status VARCHAR(50) NOT NULL, -- started, running, completed, failed, cancelled
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_ms INTEGER,
    
    -- 處理統計
    files_processed INTEGER DEFAULT 0,
    records_processed INTEGER DEFAULT 0,
    records_inserted INTEGER DEFAULT 0,
    records_updated INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,
    
    -- 錯誤處理
    error_count INTEGER DEFAULT 0,
    warning_count INTEGER DEFAULT 0,
    error_details JSONB,
    
    -- 性能指標
    processing_rate_records_per_sec DECIMAL(10,2),
    memory_usage_mb DECIMAL(8,2),
    cpu_usage_percent DECIMAL(5,2),
    
    -- 執行環境
    n8n_execution_id VARCHAR(255),
    worker_node VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 執行歷史索引
CREATE INDEX IF NOT EXISTS idx_sync_history_execution_id ON sync_execution_history(execution_id);
CREATE INDEX IF NOT EXISTS idx_sync_history_config ON sync_execution_history(config_id);
CREATE INDEX IF NOT EXISTS idx_sync_history_status ON sync_execution_history(execution_status);
CREATE INDEX IF NOT EXISTS idx_sync_history_started ON sync_execution_history(started_at);

-- ===================================
-- 5. 觸發器和函數
-- ===================================

-- 自動更新時間戳
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 應用觸發器
CREATE TRIGGER update_file_sync_log_updated_at 
    BEFORE UPDATE ON file_sync_log 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sync_configurations_updated_at 
    BEFORE UPDATE ON sync_configurations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_managed_tables_updated_at 
    BEFORE UPDATE ON managed_tables 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 同步統計更新函數
CREATE OR REPLACE FUNCTION update_sync_statistics()
RETURNS TRIGGER AS $$
BEGIN
    -- 更新配置表的執行統計
    IF NEW.sync_status = 'completed' AND OLD.sync_status != 'completed' THEN
        UPDATE sync_configurations 
        SET 
            successful_executions = successful_executions + 1,
            total_executions = total_executions + 1,
            last_execution = NEW.last_sync_time
        WHERE id = (SELECT config_id FROM sync_execution_history WHERE file_sync_log_id = NEW.id LIMIT 1);
    ELSIF NEW.sync_status = 'failed' AND OLD.sync_status != 'failed' THEN
        UPDATE sync_configurations 
        SET 
            failed_executions = failed_executions + 1,
            total_executions = total_executions + 1
        WHERE id = (SELECT config_id FROM sync_execution_history WHERE file_sync_log_id = NEW.id LIMIT 1);
    END IF;
    
    -- 更新管理表統計
    UPDATE managed_tables 
    SET 
        last_sync_time = NEW.last_sync_time,
        last_record_count = NEW.records_imported,
        sync_status = CASE 
            WHEN NEW.sync_status = 'completed' THEN 'active'
            WHEN NEW.sync_status = 'failed' THEN 'error'
            ELSE sync_status
        END
    WHERE table_name = NEW.target_table_name;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_sync_statistics
    AFTER UPDATE ON file_sync_log
    FOR EACH ROW EXECUTE FUNCTION update_sync_statistics();

-- ===================================
-- 6. 實用視圖
-- ===================================

-- 同步狀態概覽
CREATE OR REPLACE VIEW sync_status_overview AS
SELECT 
    DATE(last_sync_time) as sync_date,
    sync_status,
    COUNT(*) as file_count,
    SUM(records_imported) as total_records,
    AVG(processing_time_ms) as avg_processing_time,
    SUM(file_size_bytes) as total_file_size
FROM file_sync_log
WHERE last_sync_time >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(last_sync_time), sync_status
ORDER BY sync_date DESC, sync_status;

-- 表活躍度排行
CREATE OR REPLACE VIEW table_activity_ranking AS
SELECT 
    mt.table_name,
    mt.display_name,
    mt.total_records,
    mt.last_sync_time,
    mt.query_count,
    mt.data_quality_score,
    fsl.sync_status,
    CASE 
        WHEN mt.last_accessed > NOW() - INTERVAL '1 day' THEN 'high'
        WHEN mt.last_accessed > NOW() - INTERVAL '7 days' THEN 'medium'
        WHEN mt.last_accessed > NOW() - INTERVAL '30 days' THEN 'low'
        ELSE 'inactive'
    END as activity_level
FROM managed_tables mt
LEFT JOIN file_sync_log fsl ON mt.source_file_id = fsl.file_id
ORDER BY mt.query_count DESC, mt.last_accessed DESC;

-- 同步效能分析
CREATE OR REPLACE VIEW sync_performance_analysis AS
SELECT 
    config_name,
    COUNT(*) as total_syncs,
    AVG(duration_ms) as avg_duration_ms,
    AVG(processing_rate_records_per_sec) as avg_processing_rate,
    SUM(records_processed) as total_records_processed,
    (SUM(CASE WHEN execution_status = 'completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) as success_rate
FROM sync_configurations sc
JOIN sync_execution_history seh ON sc.id = seh.config_id
WHERE seh.started_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY sc.id, config_name
ORDER BY success_rate DESC, avg_processing_rate DESC;

-- ===================================
-- 7. 初始化配置數據
-- ===================================

-- 插入預設同步配置
INSERT INTO sync_configurations (
    config_name, 
    description, 
    source_folder_id, 
    sync_schedule,
    is_active
) VALUES (
    'default_drive_sync',
    '預設的 Google Drive 數據同步配置',
    'YOUR_DEFAULT_FOLDER_ID', -- 需要替換為實際的 Folder ID
    '*/10 * * * *',
    true
) ON CONFLICT (config_name) DO NOTHING;

-- 完成提示
SELECT 
    '🎉 Google Drive 同步系統數據庫建置完成！' as status,
    '📁 支援 CSV、Excel、JSON 自動同步' as features,
    '🔄 包含完整的監控、日誌和效能分析' as capabilities;