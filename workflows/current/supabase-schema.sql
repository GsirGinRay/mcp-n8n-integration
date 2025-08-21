-- 自學習LINE機器人 Supabase 數據庫結構
-- 創建日期: 2025-08-18

-- 1. 對話歷史表
CREATE TABLE IF NOT EXISTS conversation_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    message_id VARCHAR(255) NOT NULL UNIQUE,
    user_message TEXT NOT NULL,
    bot_response TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 對話歷史索引
CREATE INDEX IF NOT EXISTS idx_conversation_user_id ON conversation_history(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_created_at ON conversation_history(created_at);
CREATE INDEX IF NOT EXISTS idx_conversation_user_date ON conversation_history(user_id, DATE(created_at));

-- 2. 學習模式表
CREATE TABLE IF NOT EXISTS learning_patterns (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    category VARCHAR(100) NOT NULL DEFAULT 'restaurant',
    pattern_type VARCHAR(100) NOT NULL,
    pattern_description TEXT NOT NULL,
    user_input TEXT NOT NULL,
    bot_response TEXT,
    confidence_score DECIMAL(3,2) DEFAULT 0.5 CHECK (confidence_score >= 0 AND confidence_score <= 1),
    usage_count INTEGER DEFAULT 1,
    success_rate DECIMAL(3,2) DEFAULT 0.5,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 學習模式索引
CREATE INDEX IF NOT EXISTS idx_learning_category ON learning_patterns(category);
CREATE INDEX IF NOT EXISTS idx_learning_type ON learning_patterns(pattern_type);
CREATE INDEX IF NOT EXISTS idx_learning_confidence ON learning_patterns(confidence_score);
CREATE INDEX IF NOT EXISTS idx_learning_created ON learning_patterns(created_at);

-- 3. 分析數據表
CREATE TABLE IF NOT EXISTS analytics_data (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    message_type VARCHAR(50) NOT NULL,
    content_analysis JSONB,
    response_time INTEGER, -- 毫秒
    satisfaction_score DECIMAL(2,1), -- 1-5分
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 分析數據索引
CREATE INDEX IF NOT EXISTS idx_analytics_user_id ON analytics_data(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_type ON analytics_data(message_type);
CREATE INDEX IF NOT EXISTS idx_analytics_created ON analytics_data(created_at);
CREATE INDEX IF NOT EXISTS idx_analytics_content ON analytics_data USING GIN(content_analysis);

-- 4. 用戶偏好表
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL UNIQUE,
    preferences JSONB DEFAULT '{}',
    favorite_topics TEXT[],
    communication_style VARCHAR(50) DEFAULT 'friendly',
    preferred_response_length VARCHAR(20) DEFAULT 'medium',
    last_interaction TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    total_interactions INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 用戶偏好索引
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_topics ON user_preferences USING GIN(favorite_topics);
CREATE INDEX IF NOT EXISTS idx_user_preferences_style ON user_preferences(communication_style);

-- 5. 知識庫表
CREATE TABLE IF NOT EXISTS knowledge_base (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    category VARCHAR(100) NOT NULL,
    topic VARCHAR(200) NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    keywords TEXT[],
    confidence_score DECIMAL(3,2) DEFAULT 0.8,
    source VARCHAR(100) DEFAULT 'learned',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 知識庫索引
CREATE INDEX IF NOT EXISTS idx_knowledge_category ON knowledge_base(category);
CREATE INDEX IF NOT EXISTS idx_knowledge_topic ON knowledge_base(topic);
CREATE INDEX IF NOT EXISTS idx_knowledge_keywords ON knowledge_base USING GIN(keywords);
CREATE INDEX IF NOT EXISTS idx_knowledge_active ON knowledge_base(is_active);

-- 6. 觸發器：自動更新時間戳
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 應用觸發器
CREATE TRIGGER update_conversation_history_updated_at 
    BEFORE UPDATE ON conversation_history 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_learning_patterns_updated_at 
    BEFORE UPDATE ON learning_patterns 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at 
    BEFORE UPDATE ON user_preferences 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_knowledge_base_updated_at 
    BEFORE UPDATE ON knowledge_base 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. 啟用 Row Level Security (RLS)
ALTER TABLE conversation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_base ENABLE ROW LEVEL SECURITY;

-- 8. 創建 RLS 政策 (需要根據實際認證需求調整)
-- 允許服務角色完全訪問
CREATE POLICY "Enable all access for service role" ON conversation_history
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Enable all access for service role" ON learning_patterns
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Enable all access for service role" ON analytics_data
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Enable all access for service role" ON user_preferences
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Enable all access for service role" ON knowledge_base
    FOR ALL USING (auth.role() = 'service_role');

-- 9. 初始化基礎知識數據
INSERT INTO knowledge_base (category, topic, question, answer, keywords, confidence_score, source) VALUES
('restaurant', 'hours', '營業時間', '小明的餐廳營業時間為週一至週日 11:00 - 22:00', ARRAY['營業', '時間', '開店', '關店'], 1.0, 'initial'),
('restaurant', 'location', '地址位置', '小明的餐廳位於台北市中山區中山路 123 號', ARRAY['地址', '位置', '在哪', '怎麼去'], 1.0, 'initial'),
('restaurant', 'contact', '聯絡電話', '您可以撥打 02-1234-5678 聯絡小明的餐廳', ARRAY['電話', '聯絡', '預約'], 1.0, 'initial'),
('restaurant', 'service', '服務項目', '我們提供內用、外帶、外送服務，外送範圍為5公里內', ARRAY['服務', '內用', '外帶', '外送'], 1.0, 'initial'),
('restaurant', 'payment', '付款方式', '我們接受現金、信用卡、Line Pay、Apple Pay等支付方式', ARRAY['付款', '支付', '刷卡', '現金'], 1.0, 'initial'),
('restaurant', 'delivery', '外送平台', '您可以透過 Uber Eats 或 Foodpanda 訂購外送', ARRAY['外送', 'uber', 'foodpanda', '平台'], 1.0, 'initial');

-- 10. 創建視圖：用戶互動統計
CREATE OR REPLACE VIEW user_interaction_stats AS
SELECT 
    user_id,
    COUNT(*) as total_messages,
    COUNT(DISTINCT DATE(created_at)) as active_days,
    AVG(LENGTH(user_message)) as avg_message_length,
    MAX(created_at) as last_interaction,
    MIN(created_at) as first_interaction
FROM conversation_history
GROUP BY user_id;

-- 11. 創建視圖：學習模式效果統計
CREATE OR REPLACE VIEW learning_effectiveness AS
SELECT 
    pattern_type,
    category,
    COUNT(*) as pattern_count,
    AVG(confidence_score) as avg_confidence,
    AVG(success_rate) as avg_success_rate,
    MAX(updated_at) as last_updated
FROM learning_patterns
WHERE confidence_score > 0.5
GROUP BY pattern_type, category
ORDER BY avg_confidence DESC;

-- 12. 創建函數：獲取用戶個人化回應
CREATE OR REPLACE FUNCTION get_personalized_context(user_id_param VARCHAR)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'conversation_history', (
            SELECT json_agg(
                json_build_object(
                    'user_message', user_message,
                    'bot_response', bot_response,
                    'created_at', created_at
                )
            )
            FROM conversation_history 
            WHERE user_id = user_id_param 
                AND DATE(created_at) = CURRENT_DATE
            ORDER BY created_at DESC 
            LIMIT 10
        ),
        'learning_patterns', (
            SELECT json_agg(
                json_build_object(
                    'pattern_type', pattern_type,
                    'pattern_description', pattern_description,
                    'confidence_score', confidence_score
                )
            )
            FROM learning_patterns 
            WHERE confidence_score > 0.7 
            ORDER BY confidence_score DESC 
            LIMIT 20
        ),
        'user_preferences', (
            SELECT row_to_json(user_preferences.*)
            FROM user_preferences 
            WHERE user_preferences.user_id = user_id_param
        )
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 完成消息
SELECT 'Supabase自學習機器人數據庫結構創建完成！' as status;